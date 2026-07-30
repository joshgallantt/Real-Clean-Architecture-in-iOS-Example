import Combine
import Foundation
import Product
import Session
import Wishlist
import WishlistData
import WishlistDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper did, not which type did it, so the tests survive the feature being rearranged
/// underneath them.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over a real `FileWishlistStore` in a temporary directory — so what a shopper's list survives is
/// decided by the code that will actually have to survive it.
final class Saver {
    private let directory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: WishlistDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var wishlist = Wishlist()
    private(set) var heartIsFilled: [ProductID: Bool] = [:]

    init(in directory: URL = .newTemporaryDirectory, signedInAs userId: Int? = nil) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = WishlistDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: FileWishlistStore(
                directory: directory,
                legacyDefaults: UserDefaults(suiteName: UUID().uuidString)!
            )
        )

        di.observeWishlistUseCase()
            .sink { [weak self] in self?.wishlist = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper does

    @discardableResult
    func save(productId: Int) async -> Result<Void, WishlistError> {
        await di.addProductToWishlistUseCase(productId: pid(productId))
    }

    @discardableResult
    func unsave(productId: Int) async -> Result<Void, WishlistError> {
        await di.removeProductFromWishlistUseCase(productId: pid(productId))
    }

    /// The heart on a product card, which watches one product and nothing else.
    func watchTheHeart(onProductId productId: Int) {
        di.observeProductIsWishlistedUseCase(productId: pid(productId))
            .sink { [weak self] in self?.heartIsFilled[pid(productId)] = $0 }
            .store(in: &cancellables)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - Leaving and coming back

    /// No waiting for anything to settle: a save is not done until what it saved is kept, so by
    /// the time `save` has returned there is nothing in flight to wait for.
    func leaveAndComeBack() -> Saver {
        Saver(in: directory, signedInAs: signedInUserId)
    }

    private var signedInUserId: Int? {
        if case .signedIn(let id) = Owner(sessions.value) { return id.rawValue }
        return nil
    }

    private static func session(forUserId userId: Int?) -> Session {
        guard let userId else { return .guest }
        return .authenticated(
            User(
                id: UserID(rawValue: userId),
                email: Email("shopper@example.com"),
                name: PersonName(first: "Ada", last: nil)
            )
        )
    }
}

// MARK: - The session, which the wishlist only ever reads

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

// MARK: - Fixtures

extension URL {
    static var newTemporaryDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    /// Somewhere the wishlist genuinely cannot be written: a directory that cannot be created,
    /// because the path it would sit under is a file. A real failure rather than a fake store —
    /// the store under test is the one that ships.
    static func unwritableDirectory() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not a directory".utf8).write(to: file)
        return file.appending(path: "wishlist", directoryHint: .isDirectory)
    }
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
