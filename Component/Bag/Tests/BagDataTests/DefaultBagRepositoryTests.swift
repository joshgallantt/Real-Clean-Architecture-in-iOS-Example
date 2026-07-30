import Combine
import Foundation
import Testing
import Bag
import Money
import Session
@testable import BagData

/// What is left once the bag owns its rules and the use cases own the sequencing:
/// keeping the current bag, putting it on disk in the right order, swapping it when the
/// owner changes, and telling anyone watching.
@MainActor
@Suite("Keeping the bag")
struct DefaultBagRepositoryTests {

    private func makeRepository(
        store: InMemoryBagStore = InMemoryBagStore(),
        owners: CurrentValueSubject<BagOwner, Never> = CurrentValueSubject(.guest)
    ) -> DefaultBagRepository {
        DefaultBagRepository(
            store: store,
            owner: owners.value,
            ownerPublisher: owners.eraseToAnyPublisher()
        )
    }

    private func shopper(_ id: Int) -> BagOwner {
        .shopper(UserID(rawValue: id))
    }

    @Test("A saved bag is the bag anyone watching sees next")
    func savedBagsArePublished() {
        let repository = makeRepository()
        var seen: [Int] = []
        let cancellable = repository.bagPublisher.sink { seen.append($0.items.count) }

        repository.save(bag: Bag(items: [item(1, price: 1)]), changes: BagChanges())
        repository.save(bag: Bag(items: [item(1, price: 1), item(2, price: 2)]), changes: BagChanges())

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("A saved bag is the bag asked for straight afterwards")
    func savedBagIsCurrent() {
        let repository = makeRepository()

        repository.save(bag: Bag(items: [item(1, quantity: 2, price: 4.99)]), changes: BagChanges())

        #expect(repository.bag.total == usd(9.98))
    }

    @Test("Rapid saves reach the store in the order they were made")
    func writesArePersistedInOrder() async {
        let store = InMemoryBagStore()
        let repository = makeRepository(store: store)
        let first = item(1, price: 1)
        let second = item(2, price: 2)

        repository.save(bag: Bag(items: [first]), changes: BagChanges())
        repository.save(bag: Bag(items: [first, second]), changes: BagChanges())
        repository.save(bag: Bag(items: [second]), changes: BagChanges())
        await repository.flushPendingWrites()

        #expect(store.writes.map { $0.bag.items.count } == [1, 2, 1])
        #expect(store.writes.last?.bag.items.map(\.id) == [pid(2)])
    }

    @Test("A bag kept from a previous visit is there on the next one")
    func restoresAPreviousBag() {
        let kept = [
            item(1, quantity: 2, price: 4.99, addedAt: .distantPast),
            item(2, price: 9.99, addedAt: .now)
        ]
        let store = InMemoryBagStore(seeded: [.guest: (Bag(items: kept), BagChanges())])

        let repository = makeRepository(store: store)

        #expect(repository.bag.items.map(\.id) == [pid(2), pid(1)])
        #expect(repository.bag.total == usd(19.97))
    }

    @Test("Signing in swaps the guest's bag for the shopper's own")
    func switchingOwnerSwapsTheBag() {
        let store = InMemoryBagStore(seeded: [
            shopper(42): (Bag(items: [item(9, price: 5)]), BagChanges())
        ])
        let owners = CurrentValueSubject<BagOwner, Never>(.guest)
        let repository = makeRepository(store: store, owners: owners)
        repository.save(bag: Bag(items: [item(1, price: 1)]), changes: BagChanges())

        owners.send(shopper(42))

        #expect(repository.bag.items.map(\.id) == [pid(9)])
    }

    @Test("Signing out hands the guest bag back exactly as it was left")
    func signingOutRestoresTheGuestBag() async {
        let store = InMemoryBagStore()
        let owners = CurrentValueSubject<BagOwner, Never>(.guest)
        let repository = makeRepository(store: store, owners: owners)
        repository.save(bag: Bag(items: [item(1, price: 9.99)]), changes: BagChanges())
        await repository.flushPendingWrites()

        owners.send(shopper(42))
        repository.save(bag: Bag(items: [item(9, price: 5)]), changes: BagChanges())
        await repository.flushPendingWrites()
        owners.send(.guest)

        #expect(repository.bag.items.map(\.id) == [pid(1)])
        #expect(repository.bag.total == usd(9.99))
    }

    @Test("Being told the owner is who they already were leaves the bag alone")
    func sameOwnerIsNotAReload() {
        let owners = CurrentValueSubject<BagOwner, Never>(.guest)
        let repository = makeRepository(owners: owners)
        repository.save(bag: Bag(items: [item(1, price: 1)]), changes: BagChanges())

        owners.send(.guest)

        // A reload here would drop the save that has not reached disk yet.
        #expect(repository.bag.items.map(\.id) == [pid(1)])
    }

    @Test("Two shoppers' bags never mix, because they are filed under who they belong to")
    func bagsAreKeptApart() async {
        let store = InMemoryBagStore()
        let owners = CurrentValueSubject<BagOwner, Never>(shopper(1))
        let repository = makeRepository(store: store, owners: owners)

        repository.save(bag: Bag(items: [item(1, price: 1)]), changes: BagChanges())
        await repository.flushPendingWrites()
        owners.send(shopper(2))
        repository.save(bag: Bag(items: [item(2, price: 2)]), changes: BagChanges())
        await repository.flushPendingWrites()

        #expect(store.getBag(for: shopper(1)).bag.items.map(\.id) == [pid(1)])
        #expect(store.getBag(for: shopper(2)).bag.items.map(\.id) == [pid(2)])
    }
}
