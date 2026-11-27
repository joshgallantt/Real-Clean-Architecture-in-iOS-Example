import MoneyTestSupport
import Combine
import Foundation
import Bag
import BagData
import BagDI
import Money
import Product
import ProductTestSupport
import Session
import SessionTestSupport

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

    /// The catalog, which is the one thing here the app cannot own — it is somebody else's shop,
    /// over HTTP. Everything else in this driver is the real thing.
    let shop = FakeLookUpProductsUseCase()

    /// The bag as it is kept, which is the bag as they last saw it.
    private(set) var bag = Bag()

    /// What they were shown the last time they looked: the bag as it truthfully was, and what had
    /// changed about it. Nothing, until they look.
    private(set) var shown = Bag().checked(against: [], asked: [])

    init(in directory: URL = .newTemporaryDirectory, signedInAs userId: Int? = nil) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = BagDI(
            getSession: StubGetSessionUseCase(sessions: sessions),
            observeSession: SpyObserveSessionUseCase(sessions: sessions),
            lookUpProducts: shop,
            store: FileBagStore(directory: directory)
        )

        di.observeBagUseCase()
            .sink { [weak self] in self?.bag = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper does

    func choose(productId: Int, atPrice price: Decimal) {
        di.setBagItemUseCase(
            BagItem(productId: pid(productId), quantity: bag.quantity(of: pid(productId)) + 1, lastKnownPrice: usd(price))
        )
    }

    func changeQuantity(ofProductId productId: Int, to quantity: Int) {
        set(productId, to: quantity)
    }

    func remove(productId: Int) {
        set(productId, to: 0)
    }

    private func set(_ productId: Int, to quantity: Int) {
        guard let line = bag.items.first(where: { $0.productId == pid(productId) }) else { return }
        di.setBagItemUseCase(line.withQuantity(quantity))
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - What the shop does

    /// What the shop sells now. Anything not listed here it has stopped selling, which is the only
    /// signal a real shop gives — there is no fixture for "discontinued" because there cannot be.
    func theShopNowSells(_ products: OnTheShelf...) {
        shop.stock = products
    }

    /// The shopper looks in their bag, and is shown it as the shop says it is today.
    func looks() async {
        shown = await di.checkBagUseCase()
    }

    /// They look, and the shop could not be reached at all. Nothing was learned, so nothing may be
    /// concluded.
    func looksWhileTheShopCannotBeReached() async {
        shop.cannotBeReached = true
        await looks()
        shop.cannotBeReached = false
    }

    /// The shopper leaves the bag, and it is kept as they just saw it — which is what makes
    /// everything they were told old news.
    func leaves() {
        for line in bag.lines(toBecome: shown.bag) {
            di.setBagItemUseCase(line)
        }
    }

    /// Looked and left: the whole of a visit to the bag.
    func visits() async {
        await looks()
        leaves()
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
        for _ in 0..<100 where onDisk.getBag(for: sessions.value) != bag {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private var signedInUserId: Int? {
        if case .authenticated(let user) = sessions.value { return user.id.rawValue }
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

// MARK: - Fixtures

extension URL {
    static var newTemporaryDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }
}

// MARK: - What the shop has on the shelf

func shopSells(_ id: Int, at price: Decimal, remaining: Int = 10) -> OnTheShelf {
    OnTheShelf(product: product(id, price: price, availability: .inStock(remaining: remaining)))
}

func shopHasSoldOutOf(_ id: Int, at price: Decimal = 1) -> OnTheShelf {
    OnTheShelf(product: product(id, price: price, availability: .outOfStock))
}

/// There is no fixture for something the shop has stopped selling, and there cannot be: a shop
/// stops selling something by not answering about it. Leave it off the shelf and the bag draws the
/// same conclusion the real one does.
private func product(_ id: Int, price: Decimal, availability: Availability) -> Product {
    Product(
        id: pid(id),
        title: "Product \(id)",
        description: "",
        category: CategoryID(rawValue: "beauty"),
        price: usd(price),
        rating: 4.5,
        availability: availability,
        brand: "Acme",
        thumbnail: "https://cdn.example.com/\(id).png",
        images: []
    )
}
