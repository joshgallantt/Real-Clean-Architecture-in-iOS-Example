import Combine
import Foundation
import Testing
import Session
import Wishlist
import WishlistData
import WishlistDI

/// Journeys through the whole feature — use cases, repository and store — as the
/// composition root wires it.
@MainActor
@Suite("Saving products for later")
struct SavingProductsTests {

    @Test("A signed-in shopper saves two things and finds both waiting, most recent first")
    func savesTwoThings() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        #expect(shopper.wishlist.items.map(\.id) == [2, 1])
    }

    @Test("Tapping the heart twice on the same product saves it once")
    func savingTwice() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: 1)
        await shopper.save(productId: 1)

        #expect(shopper.wishlist.count == 1)
    }

    @Test("Unsaving takes it out and leaves the rest")
    func unsaving() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        await shopper.unsave(productId: 1)

        #expect(shopper.wishlist.items.map(\.id) == [2])
    }

    @Test("A guest is asked to sign in rather than quietly saving nothing")
    func guestIsAskedToSignIn() async {
        let shopper = Saver()

        let result = await shopper.save(productId: 1)

        #expect(result.failure == .unauthenticated)
        #expect(shopper.wishlist.isEmpty)
    }

    @Test("A shopper's saved products are still there when they come back")
    func listSurvivesLeaving() async {
        let store = InMemoryWishlistStore()
        let firstVisit = Saver(store: store, signedInAs: 42)
        await firstVisit.save(productId: 1)
        await firstVisit.save(productId: 2)
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Saver(store: store, signedInAs: 42)

        #expect(nextVisit.wishlist.items.map(\.id) == [2, 1])
    }

    @Test("Two shoppers do not see each other's saved products")
    func listsAreNotShared() async {
        let store = InMemoryWishlistStore()
        let first = Saver(store: store, signedInAs: 1)
        await first.save(productId: 7)
        try? await Task.sleep(for: .milliseconds(50))

        let second = Saver(store: store, signedInAs: 2)

        #expect(second.wishlist.isEmpty)
    }
}

/// The wishlist feature wired as the composition root wires it, over an in-memory store.
@MainActor
final class Saver {
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: WishlistDI
    private var cancellables = Set<AnyCancellable>()
    private(set) var wishlist = Wishlist()

    init(store: WishlistStore = InMemoryWishlistStore(), signedInAs userId: Int? = nil) {
        let session: Session = userId.map {
            .authenticated(User(id: $0, email: "", firstName: "", lastName: ""))
        } ?? .guest
        self.sessions = CurrentValueSubject(session)
        self.di = WishlistDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            userIsLoggedIn: StubUserIsLoggedIn(sessions: sessions),
            store: store
        )

        di.observeWishlistUseCase()
            .sink { [weak self] in self?.wishlist = $0 }
            .store(in: &cancellables)
    }

    @discardableResult
    func save(productId: Int) async -> Result<Void, WishlistError> {
        await di.addProductToWishlistUseCase(productId: productId)
    }

    @discardableResult
    func unsave(productId: Int) async -> Result<Void, WishlistError> {
        await di.removeProductFromWishlistUseCase(productId: productId)
    }
}

private struct StubGetSession: GetSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> Session { sessions.value }
}

private struct StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never> { sessions.eraseToAnyPublisher() }
}

private struct StubUserIsLoggedIn: UserIsLoggedInUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    func callAsFunction() async -> Bool { sessions.value.isLoggedIn }
}

final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private let lock = NSLock()
    private var lists: [String: [WishlistItem]]

    init(seeded: [String: [WishlistItem]] = [:]) {
        self.lists = seeded
    }

    func getItems(forUserKey userKey: String) -> [WishlistItem] {
        lock.withLock { lists[userKey] ?? [] }
    }

    func setItems(_ items: [WishlistItem], forUserKey userKey: String) async {
        lock.withLock { lists[userKey] = items }
    }
}

private extension Result where Success == Void, Failure: Equatable {
    var isSuccess: Bool { if case .success = self { true } else { false } }
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
