import Combine
import Foundation
import Testing
import Product
import Session
import Wishlist
@testable import WishlistData

/// Keeping the current list, putting it on disk in the right order, swapping it when
/// the owner changes, and telling anyone watching. Nothing here decides what saving
/// or removing means.
@MainActor
@Suite("Keeping the wishlist")
struct DefaultWishlistRepositoryTests {

    private func makeRepository(
        store: InMemoryWishlistStore = InMemoryWishlistStore(),
        owners: CurrentValueSubject<UserID?, Never> = CurrentValueSubject(UserID(rawValue: 1))
    ) -> DefaultWishlistRepository {
        DefaultWishlistRepository(
            store: store,
            owner: owners.value,
            ownerPublisher: owners.eraseToAnyPublisher()
        )
    }

    @Test("A saved list is the list anyone watching sees next")
    func savedListsArePublished() {
        let repository = makeRepository()
        var seen: [Int] = []
        let cancellable = repository.wishlistPublisher.sink { seen.append($0.itemCount) }

        repository.save(Wishlist(items: [WishlistItem(productId: pid(1))]))
        repository.save(Wishlist(items: [WishlistItem(productId: pid(1)), WishlistItem(productId: pid(2))]))

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("Rapid toggles reach the store in the order they were made")
    func writesArePersistedInOrder() async {
        let store = InMemoryWishlistStore()
        let repository = makeRepository(store: store)
        let first = WishlistItem(productId: pid(1))
        let second = WishlistItem(productId: pid(2))

        repository.save(Wishlist(items: [first]))
        repository.save(Wishlist(items: [first, second]))
        repository.save(Wishlist(items: [second]))
        await repository.flushPendingWrites()

        #expect(store.writes.map(\.count) == [1, 2, 1])
        #expect(store.writes.last?.map(\.productId) == [pid(2)])
    }

    @Test("A list kept from a previous visit is there on the next one, newest first")
    func restoresAPreviousList() {
        let kept = [
            WishlistItem(productId: pid(1), dateAdded: .distantPast),
            WishlistItem(productId: pid(2), dateAdded: .now)
        ]
        let store = InMemoryWishlistStore(seeded: [UserID(rawValue: 1): kept])

        let repository = makeRepository(store: store)

        #expect(repository.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Signing in as someone else swaps in their list")
    func switchingOwnerSwapsTheList() {
        let store = InMemoryWishlistStore(seeded: [UserID(rawValue: 42): [WishlistItem(productId: pid(9))]])
        let owners = CurrentValueSubject<UserID?, Never>(UserID(rawValue: 1))
        let repository = makeRepository(store: store, owners: owners)
        repository.save(Wishlist(items: [WishlistItem(productId: pid(1))]))

        owners.send(UserID(rawValue: 42))

        #expect(repository.wishlist.items.map(\.id) == [pid(9)])
    }

    @Test("Being told the owner is who they already were leaves the list alone")
    func sameOwnerIsNotAReload() {
        let owners = CurrentValueSubject<UserID?, Never>(UserID(rawValue: 1))
        let repository = makeRepository(owners: owners)
        repository.save(Wishlist(items: [WishlistItem(productId: pid(1))]))

        owners.send(UserID(rawValue: 1))

        // A reload here would drop the save that has not reached disk yet.
        #expect(repository.wishlist.items.map(\.id) == [pid(1)])
    }
}

final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private let lock = NSLock()
    private var lists: [UserID?: [WishlistItem]]
    private var _writes: [[WishlistItem]] = []

    var writes: [[WishlistItem]] { lock.withLock { _writes } }

    init(seeded: [UserID?: [WishlistItem]] = [:]) {
        self.lists = seeded
    }

    func getItems(for owner: UserID?) -> [WishlistItem] {
        lock.withLock { lists[owner] ?? [] }
    }

    func setItems(_ items: [WishlistItem], for owner: UserID?) async {
        lock.withLock {
            lists[owner] = items
            _writes.append(items)
        }
    }
}


// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}
