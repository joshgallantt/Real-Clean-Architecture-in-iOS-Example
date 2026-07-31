import Combine
import Foundation
import Bag
import BagData
import BagDI
import Money
import Product
import Session

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper did, not which type did it, so the tests survive the feature being rearranged
/// underneath them. Structural coupling is the coupling Martin warns tests are most prone to.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over a real `FileBagStore` in a temporary directory. Only where the bag is *kept* is stood in
/// for, and even that is the real implementation — so what a shopper's bag survives is decided by
/// the code that will actually have to survive it.
final class Shopper {
    private let directory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: BagDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var bag = Bag()
    private(set) var news = Notices()

    init(in directory: URL = .newTemporaryDirectory, signedInAs userId: Int? = nil) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = BagDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: FileBagStore(directory: directory)
        )

        di.observeBagUseCase()
            .sink { [weak self] in self?.bag = $0 }
            .store(in: &cancellables)

        di.observeNoticesUseCase()
            .sink { [weak self] in self?.news = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper does

    func choose(productId: Int, atPrice price: Decimal) {
        di.addItemToBagUseCase(
            BagItem(productId: pid(productId), lastKnownPrice: usd(price))
        )
    }

    func changeQuantity(ofProductId productId: Int, to quantity: Int) {
        di.setBagItemQuantityUseCase(productId: pid(productId), to: quantity)
    }

    func remove(productId: Int) {
        di.setBagItemQuantityUseCase(productId: pid(productId), to: 0)
    }

    func seen(productId: Int) {
        di.acknowledgeNoticesUseCase(aboutProductId: pid(productId))
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - What the shop does

    /// The shop is asked about everything the bag holds, and answers about what it still sells.
    /// Anything it does not describe it has stopped selling, which is the only signal a real shop
    /// gives.
    func shopSays(_ shopSays: ShopSays...) {
        di.bringBagUpToDateUseCase(against: shopSays, asked: bag.items.map(\.productId))
    }

    /// A catch-up that never reached the shop at all — nothing was asked, so nothing is concluded.
    func theShopIsNotReached() {
        di.bringBagUpToDateUseCase(against: [], asked: [])
    }

    // MARK: - Leaving and coming back

    /// The shopper closes the app and opens it again. Waits for what they did to reach the disk
    /// first, so a journey that ends here is asserting what was *kept*, not what was still in
    /// flight.
    func leaveAndComeBack() async -> Shopper {
        await writesToSettle()
        return Shopper(in: directory, signedInAs: signedInUserId)
    }

    func writesToSettle() async {
        let onDisk = FileBagStore(directory: directory)
        for _ in 0..<100 where onDisk.getBag(for: Owner(sessions.value)).bag != bag {
            try? await Task.sleep(for: .milliseconds(10))
        }
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

// MARK: - The session, which the bag only ever reads

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
}

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

// MARK: - What the shop says

func shopSells(_ id: Int, at price: Decimal, remaining: Int = 10) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(price), availability: .inStock(remaining: remaining))
}

func shopHasSoldOutOf(_ id: Int) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(1), availability: .outOfStock)
}

/// There is no fixture for something the shop has stopped selling, and there cannot be: a shop
/// stops selling something by not answering about it. Leave it out of `shopSays` and the bag draws
/// the same conclusion the real one does.
