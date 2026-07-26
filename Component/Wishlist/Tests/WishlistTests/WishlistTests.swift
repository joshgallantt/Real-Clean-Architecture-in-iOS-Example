import XCTest
import Combine
@testable import Wishlist
@testable import WishlistData

final class WishlistTests: XCTestCase {
    @MainActor
    func test_wishlist_isScopedToUser_persistsAndReacts() async {
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

        await repository.flushPendingWrites()
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

    @MainActor
    func test_persistedWrites_landInOrder() async {
        let store = InMemoryWishlistStore()
        let repository = DefaultWishlistRepository(
            store: store,
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        for id in 1...20 {
            repository.add(productId: id)
        }
        repository.remove(productId: 10)

        await repository.flushPendingWrites()

        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), repository.items.map(\.id))
        XCTAssertFalse(store.getItems(forUserKey: "42").contains { $0.id == 10 })
    }

    @MainActor
    func test_newlyAddedItems_comeFirst() {
        let repository = DefaultWishlistRepository(
            store: InMemoryWishlistStore(),
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        repository.add(productId: 1)
        repository.add(productId: 2)
        repository.add(productId: 3)

        XCTAssertEqual(repository.items.map(\.id), [3, 2, 1])
    }

    @MainActor
    func test_existingOldestFirstList_isReorderedOnLoad() {
        let now = Date()
        let store = InMemoryWishlistStore()
        store.seed(
            [
                WishlistItem(id: 1, dateAdded: now.addingTimeInterval(-300)),
                WishlistItem(id: 2, dateAdded: now.addingTimeInterval(-200)),
                WishlistItem(id: 3, dateAdded: now.addingTimeInterval(-100))
            ],
            forUserKey: "42"
        )

        let repository = DefaultWishlistRepository(
            store: store,
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        XCTAssertEqual(repository.items.map(\.id), [3, 2, 1])
    }

    func test_fileStore_roundTripsPerUser() async {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileWishlistStore(directory: directory)

        XCTAssertTrue(store.getItems(forUserKey: "42").isEmpty)

        await store.setItems([WishlistItem(id: 1), WishlistItem(id: 2)], forUserKey: "42")
        await store.setItems([WishlistItem(id: 9)], forUserKey: "guest")

        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [1, 2])
        XCTAssertEqual(store.getItems(forUserKey: "guest").map(\.id), [9])
    }

    func test_fileStore_migratesLegacyUserDefaultsWishlist() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let legacy = [WishlistItem(id: 4), WishlistItem(id: 5)]
        defaults.set(
            try JSONEncoder().encode(legacy.map(WishlistItemDTO.init(from:))),
            forKey: "wishlist.42"
        )

        let store = FileWishlistStore(directory: directory, legacyDefaults: defaults)

        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [4, 5])

        // The legacy key is cleared and the data now lives in the file, so a
        // second read does not depend on UserDefaults at all.
        XCTAssertNil(defaults.data(forKey: "wishlist.42"))
        XCTAssertEqual(
            FileWishlistStore(directory: directory, legacyDefaults: defaults)
                .getItems(forUserKey: "42").map(\.id),
            [4, 5]
        )
    }

    func test_fileStore_isUnaffectedWhenNoLegacyDataExists() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileWishlistStore(directory: directory, legacyDefaults: defaults)

        XCTAssertTrue(store.getItems(forUserKey: "42").isEmpty)
    }
}

private final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: [WishlistItem]] = [:]

    func seed(_ items: [WishlistItem], forUserKey userKey: String) {
        lock.withLock { storage[userKey] = items }
    }

    func getItems(forUserKey userKey: String) -> [WishlistItem] {
        lock.withLock { storage[userKey] ?? [] }
    }

    func setItems(_ items: [WishlistItem], forUserKey userKey: String) async {
        lock.withLock { storage[userKey] = items }
    }
}
