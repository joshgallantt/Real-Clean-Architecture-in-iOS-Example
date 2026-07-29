import Combine
import Foundation
import Testing
import Wishlist
@testable import WishlistData

/// Keeping the current list, putting it on disk in the right order, swapping it when
/// the shopper changes, and telling anyone watching. Nothing here decides what saving
/// or removing means.
@MainActor
@Suite("Keeping the wishlist")
struct DefaultWishlistRepositoryTests {

    private func makeRepository(
        store: InMemoryWishlistStore = InMemoryWishlistStore(),
        userKeys: CurrentValueSubject<String, Never> = CurrentValueSubject("guest")
    ) -> DefaultWishlistRepository {
        DefaultWishlistRepository(
            store: store,
            userKey: userKeys.value,
            userKeyPublisher: userKeys.eraseToAnyPublisher()
        )
    }

    @Test("A saved list is the list anyone watching sees next")
    func savedListsArePublished() {
        let repository = makeRepository()
        var seen: [Int] = []
        let cancellable = repository.wishlistPublisher.sink { seen.append($0.count) }

        repository.save(Wishlist(items: [WishlistItem(id: 1)]))
        repository.save(Wishlist(items: [WishlistItem(id: 1), WishlistItem(id: 2)]))

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("Rapid toggles reach the store in the order they were made")
    func writesArePersistedInOrder() async {
        let store = InMemoryWishlistStore()
        let repository = makeRepository(store: store)
        let first = WishlistItem(id: 1)
        let second = WishlistItem(id: 2)

        repository.save(Wishlist(items: [first]))
        repository.save(Wishlist(items: [first, second]))
        repository.save(Wishlist(items: [second]))
        await repository.flushPendingWrites()

        #expect(store.writes.map { $0.map(\.id).sorted() } == [[1], [1, 2], [2]])
    }

    @Test("A list kept from a previous visit is there on the next one, newest first")
    func restoresAPreviousList() {
        let kept = [
            WishlistItem(id: 1, dateAdded: .distantPast),
            WishlistItem(id: 2, dateAdded: .now)
        ]
        let store = InMemoryWishlistStore(seeded: ["guest": kept])

        let repository = makeRepository(store: store)

        #expect(repository.wishlist.items.map(\.id) == [2, 1])
    }

    @Test("Signing in swaps the guest's list for the shopper's own")
    func switchingUserSwapsTheList() {
        let store = InMemoryWishlistStore(seeded: ["42": [WishlistItem(id: 9)]])
        let userKeys = CurrentValueSubject<String, Never>("guest")
        let repository = makeRepository(store: store, userKeys: userKeys)
        repository.save(Wishlist(items: [WishlistItem(id: 1)]))

        userKeys.send("42")

        #expect(repository.wishlist.items.map(\.id) == [9])
    }

    @Test("Being told the shopper is who they already were leaves the list alone")
    func sameUserIsNotAReload() {
        let userKeys = CurrentValueSubject<String, Never>("guest")
        let repository = makeRepository(userKeys: userKeys)
        repository.save(Wishlist(items: [WishlistItem(id: 1)]))

        userKeys.send("guest")

        // A reload here would drop the save that has not reached disk yet.
        #expect(repository.wishlist.items.map(\.id) == [1])
    }
}

final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private let lock = NSLock()
    private var lists: [String: [WishlistItem]]
    private var _writes: [[WishlistItem]] = []

    var writes: [[WishlistItem]] { lock.withLock { _writes } }

    init(seeded: [String: [WishlistItem]] = [:]) {
        self.lists = seeded
    }

    func getItems(forUserKey userKey: String) -> [WishlistItem] {
        lock.withLock { lists[userKey] ?? [] }
    }

    func setItems(_ items: [WishlistItem], forUserKey userKey: String) async {
        lock.withLock {
            lists[userKey] = items
            _writes.append(items)
        }
    }
}
