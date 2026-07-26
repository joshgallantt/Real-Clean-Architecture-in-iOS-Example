import XCTest
import Combine
@testable import Bag
@testable import BagData

final class BagTests: XCTestCase {
    @MainActor
    func test_bag_isScopedToUser_persistsAndReacts() async {
        let store = InMemoryBagStore()
        let userKeySubject = CurrentValueSubject<String, Never>("42")
        let repository = DefaultBagRepository(
            store: store,
            userKey: userKeySubject.value,
            userKeyPublisher: userKeySubject.eraseToAnyPublisher()
        )

        var quantities: [Int] = []
        let cancellable = repository.quantityPublisher(productId: 7)
            .sink { quantities.append($0) }

        repository.add(productId: 7)
        XCTAssertEqual(repository.items.map(\.id), [7])

        await repository.flushPendingWrites()
        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [7])

        // Switching to guest surfaces a different, empty bag.
        userKeySubject.send("guest")
        XCTAssertTrue(repository.items.isEmpty)

        // Returning to the user restores their persisted bag.
        userKeySubject.send("42")
        XCTAssertEqual(repository.items.map(\.id), [7])

        XCTAssertEqual(quantities, [0, 1, 0, 1])
        cancellable.cancel()
    }

    @MainActor
    func test_add_incrementsQuantityForExistingItem() {
        let repository = DefaultBagRepository(
            store: InMemoryBagStore(),
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        repository.add(productId: 1)
        repository.add(productId: 1)
        repository.add(productId: 1)

        XCTAssertEqual(repository.items.map(\.quantity), [3])
    }

    @MainActor
    func test_updateQuantity_removesItemWhenZeroOrLess() {
        let repository = DefaultBagRepository(
            store: InMemoryBagStore(),
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        repository.add(productId: 1)
        repository.updateQuantity(productId: 1, quantity: 5)
        XCTAssertEqual(repository.items.map(\.quantity), [5])

        repository.updateQuantity(productId: 1, quantity: 0)
        XCTAssertTrue(repository.items.isEmpty)
    }

    @MainActor
    func test_newlyAddedItems_comeFirst() {
        let repository = DefaultBagRepository(
            store: InMemoryBagStore(),
            userKey: "42",
            userKeyPublisher: Empty().eraseToAnyPublisher()
        )

        repository.add(productId: 1)
        repository.add(productId: 2)
        repository.add(productId: 3)

        XCTAssertEqual(repository.items.map(\.id), [3, 2, 1])
    }

    func test_fileStore_roundTripsPerUser() async {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileBagStore(directory: directory)

        XCTAssertTrue(store.getItems(forUserKey: "42").isEmpty)

        await store.setItems([BagItem(id: 1, quantity: 2), BagItem(id: 2, quantity: 1)], forUserKey: "42")
        await store.setItems([BagItem(id: 9, quantity: 1)], forUserKey: "guest")

        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [1, 2])
        XCTAssertEqual(store.getItems(forUserKey: "guest").map(\.id), [9])
    }
}

private final class InMemoryBagStore: BagStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: [BagItem]] = [:]

    func getItems(forUserKey userKey: String) -> [BagItem] {
        lock.withLock { storage[userKey] ?? [] }
    }

    func setItems(_ items: [BagItem], forUserKey userKey: String) async {
        lock.withLock { storage[userKey] = items }
    }
}
