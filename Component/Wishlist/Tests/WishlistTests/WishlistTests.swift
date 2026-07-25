import XCTest
import Combine
import Session
@testable import Wishlist
@testable import WishlistData

final class WishlistTests: XCTestCase {
    @MainActor
    func test_wishlist_isScopedToUser_persistsAndReacts() {
        let store = InMemoryWishlistStore()
        let holder = SessionHolder(.authenticated(Self.user(id: 42)))
        let repository = DefaultWishlistRepository(
            store: store,
            getSession: FakeGetSession(holder: holder),
            observeSession: FakeObserveSession(holder: holder)
        )

        var membership: [Bool] = []
        let cancellable = repository.isInWishlistPublisher(productId: 7)
            .sink { membership.append($0) }

        repository.add(productId: 7)
        XCTAssertEqual(repository.items.map(\.id), [7])
        XCTAssertEqual(store.getItems(forUserKey: "42").map(\.id), [7])

        // Switching to guest surfaces a different, empty list.
        holder.subject.send(.guest)
        XCTAssertTrue(repository.items.isEmpty)

        // Returning to the user restores their persisted list.
        holder.subject.send(.authenticated(Self.user(id: 42)))
        XCTAssertEqual(repository.items.map(\.id), [7])

        XCTAssertEqual(membership, [false, true, false, true])
        cancellable.cancel()
    }

    private static func user(id: Int) -> User {
        User(id: id, email: "u\(id)@example.com", firstName: "", lastName: "")
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

private final class SessionHolder: @unchecked Sendable {
    let subject: CurrentValueSubject<Session, Never>
    init(_ session: Session) {
        self.subject = CurrentValueSubject(session)
    }
}

private struct FakeGetSession: GetSessionUseCase {
    let holder: SessionHolder
    @MainActor func callAsFunction() -> Session { holder.subject.value }
}

private struct FakeObserveSession: ObserveSessionUseCase {
    let holder: SessionHolder
    @MainActor func callAsFunction() -> AnyPublisher<Session, Never> { holder.subject.eraseToAnyPublisher() }
}
