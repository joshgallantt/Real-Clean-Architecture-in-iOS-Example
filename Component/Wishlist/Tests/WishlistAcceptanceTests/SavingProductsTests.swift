import Combine
import Foundation
import Testing
import Product
import Session
import Wishlist
import WishlistData
import WishlistDI

@MainActor
@Suite("Saving products for later")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. What no layer test
/// can show is that the layers fit together.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct SavingProductsTests {
    @Test("A signed-in shopper saves two things and finds both waiting, most recent first")
    func savesTwoThings() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: pid(1))
        await shopper.save(productId: pid(2))

        #expect(shopper.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Tapping the heart twice on the same product saves it once")
    func savingTwice() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: pid(1))
        await shopper.save(productId: pid(1))

        #expect(shopper.wishlist.itemCount == 1)
    }

    @Test("Unsaving takes it out and leaves the rest")
    func unsaving() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: pid(1))
        await shopper.save(productId: pid(2))

        await shopper.unsave(productId: pid(1))

        #expect(shopper.wishlist.items.map(\.id) == [pid(2)])
    }

    @Test("A guest is asked to sign in rather than quietly saving nothing")
    func guestIsAskedToSignIn() async {
        let shopper = Saver()

        let result = await shopper.save(productId: pid(1))

        #expect(result.failure == .unauthenticated)
        #expect(shopper.wishlist.isEmpty)
    }

    @Test("A shopper's saved products are still there when they come back")
    func listSurvivesLeaving() async {
        let store = InMemoryWishlistStore()
        let firstVisit = Saver(store: store, signedInAs: 42)
        await firstVisit.save(productId: pid(1))
        await firstVisit.save(productId: pid(2))
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Saver(store: store, signedInAs: 42)

        #expect(nextVisit.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Two shoppers do not see each other's saved products")
    func listsAreNotShared() async {
        let store = InMemoryWishlistStore()
        let first = Saver(store: store, signedInAs: 1)
        await first.save(productId: pid(7))
        try? await Task.sleep(for: .milliseconds(50))

        let second = Saver(store: store, signedInAs: 2)

        #expect(second.wishlist.isEmpty)
    }
}

@MainActor
final class Saver {
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: WishlistDI
    private var cancellables = Set<AnyCancellable>()
    private(set) var wishlist = Wishlist()

    init(store: WishlistStore = InMemoryWishlistStore(), signedInAs userId: Int? = nil) {
        let session: Session = userId.map {
            .authenticated(
                User(
                    id: UserID(rawValue: $0),
                    email: Email("shopper@example.com"),
                    name: PersonName(first: "Ada", last: nil)
                )
            )
        } ?? .guest
        self.sessions = CurrentValueSubject(session)
        self.di = WishlistDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: store
        )

        di.observeWishlistUseCase()
            .sink { [weak self] in self?.wishlist = $0 }
            .store(in: &cancellables)
    }

    @discardableResult
    func save(productId: ProductID) async -> Result<Void, WishlistError> {
        await di.addProductToWishlistUseCase(productId: productId)
    }

    @discardableResult
    func unsave(productId: ProductID) async -> Result<Void, WishlistError> {
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

final class InMemoryWishlistStore: WishlistStore, @unchecked Sendable {
    private let lock = NSLock()
    private var lists: [UserID?: [WishlistItem]]

    init(seeded: [UserID?: [WishlistItem]] = [:]) {
        self.lists = seeded
    }

    func getItems(for owner: UserID?) -> [WishlistItem] {
        lock.withLock { lists[owner] ?? [] }
    }

    func setItems(_ items: [WishlistItem], for owner: UserID?) async {
        lock.withLock { lists[owner] = items }
    }
}

private extension Result where Success == Void, Failure: Equatable {
    var isSuccess: Bool { if case .success = self { true } else { false } }
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}
