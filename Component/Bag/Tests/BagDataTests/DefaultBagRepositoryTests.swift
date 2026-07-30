import Combine
import Foundation
import Testing
import Bag
@testable import BagData

/// What is left once the bag owns its rules and the use cases own the sequencing:
/// keeping the current bag, putting it on disk in the right order, swapping it when the
/// shopper changes, and telling anyone watching.
@MainActor
@Suite("Keeping the bag")
struct DefaultBagRepositoryTests {

    private func makeRepository(
        store: InMemoryBagStore = InMemoryBagStore(),
        userKeys: CurrentValueSubject<String, Never> = CurrentValueSubject("guest")
    ) -> DefaultBagRepository {
        DefaultBagRepository(
            store: store,
            userKey: userKeys.value,
            userKeyPublisher: userKeys.eraseToAnyPublisher()
        )
    }

    @Test("A saved bag is the bag anyone watching sees next")
    func savedBagsArePublished() {
        let repository = makeRepository()
        var seen: [Int] = []
        let cancellable = repository.bagPublisher.sink { seen.append($0.items.count) }

        repository.save(bag: Bag(items: [BagItem(productId: 1, lastKnownPrice: 1)]), changes: BagChanges())
        repository.save(bag: Bag(items: [BagItem(productId: 1, lastKnownPrice: 1), BagItem(productId: 2, lastKnownPrice: 2)]), changes: BagChanges())

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("A saved bag is the bag asked for straight afterwards")
    func savedBagIsCurrent() {
        let repository = makeRepository()

        repository.save(bag: Bag(items: [BagItem(productId: 1, quantity: 2, lastKnownPrice: 4.99)]), changes: BagChanges())

        #expect(repository.bag.total.cents == 998)
    }

    @Test("Rapid saves reach the store in the order they were made")
    func writesArePersistedInOrder() async {
        let store = InMemoryBagStore()
        let repository = makeRepository(store: store)
        let first = BagItem(productId: 1, lastKnownPrice: 1)
        let second = BagItem(productId: 2, lastKnownPrice: 2)

        repository.save(bag: Bag(items: [first]), changes: BagChanges())
        repository.save(bag: Bag(items: [first, second]), changes: BagChanges())
        repository.save(bag: Bag(items: [second]), changes: BagChanges())
        await repository.flushPendingWrites()

        #expect(store.writes.map { $0.bag.items.map(\.id).sorted() } == [[1], [1, 2], [2]])
    }

    @Test("A bag kept from a previous visit is there on the next one")
    func restoresAPreviousBag() {
        let kept = [
            BagItem(productId: 1, quantity: 2, lastKnownPrice: 4.99, dateAdded: .distantPast),
            BagItem(productId: 2, lastKnownPrice: 9.99, dateAdded: .now)
        ]
        let store = InMemoryBagStore(seeded: ["guest": (Bag(items: kept), BagChanges())])

        let repository = makeRepository(store: store)

        #expect(repository.bag.items.map(\.id) == [2, 1])
        #expect(repository.bag.total.cents == 1997)
    }

    @Test("Signing in swaps the guest's bag for the shopper's own")
    func switchingUserSwapsTheBag() {
        let store = InMemoryBagStore(seeded: ["42": (Bag(items: [BagItem(productId: 9, lastKnownPrice: 5)]), BagChanges())])
        let userKeys = CurrentValueSubject<String, Never>("guest")
        let repository = makeRepository(store: store, userKeys: userKeys)
        repository.save(bag: Bag(items: [BagItem(productId: 1, lastKnownPrice: 1)]), changes: BagChanges())

        userKeys.send("42")

        #expect(repository.bag.items.map(\.id) == [9])
    }

    @Test("Being told the shopper is who they already were leaves the bag alone")
    func sameUserIsNotAReload() {
        let userKeys = CurrentValueSubject<String, Never>("guest")
        let repository = makeRepository(userKeys: userKeys)
        repository.save(bag: Bag(items: [BagItem(productId: 1, lastKnownPrice: 1)]), changes: BagChanges())

        userKeys.send("guest")

        // A reload here would drop the save that has not reached disk yet.
        #expect(repository.bag.items.map(\.id) == [1])
    }
}
