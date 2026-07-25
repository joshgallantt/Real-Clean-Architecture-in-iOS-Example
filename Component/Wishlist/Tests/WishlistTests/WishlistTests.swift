import XCTest
import Combine
@testable import Wishlist
@testable import WishlistData

final class WishlistTests: XCTestCase {
    @MainActor
    func test_wishlist_isScopedToUser_persistsAndReacts() {
        let store = InMemoryWishlistStore()
        let userKeySubject = CurrentValueSubject<String, Never>("42")
        let repository = DefaultWishlistRepository(
            store: store,
            userKey: userKeySubject.value,
            userKeyPublisher: userKeySubject.eraseToAnyPublisher()
        )

        var membership: [Bool] = []
        let cancellable = repository.isInWishlistPublisher(productId: 7)
            .sink { membership.append($0) }

        repository.add(productId: 7)
        XCTAssertEqual(repository.items.map(\.id), [7])
        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [7])

        // Switching to guest surfaces a different, empty list.
        userKeySubject.send("guest")
        XCTAssertTrue(repository.items.isEmpty)

        // Returning to the user restores their persisted list.
        userKeySubject.send("42")
        XCTAssertEqual(repository.items.map(\.id), [7])

        XCTAssertEqual(membership, [false, true, false, true])
        cancellable.cancel()
    }
}

private final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private var storage: [String: [WishlistItem]] = [:]

    func getItems(forUserKey userKey: String) -> [WishlistItem] {
        storage[userKey] ?? []
    }

    func setItems(_ items: [WishlistItem], forUserKey userKey: String) {
        storage[userKey] = items
    }
}
