import Combine
import Foundation
import Money
import Product
import Session
import StockAlert
import StockAlertData
import StockAlertDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper asked for and what they were shown afterwards, never which type held it.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over a real `FileStockAlertStore` in a temporary directory.
final class Waiter {
    private let directory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: StockAlertDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var bellIsRinging: [ProductID: Bool] = [:]

    /// The one thing the app cannot own here: the catalog.
    let shop = StubCatalog()

    private(set) var alerts = StockAlerts()

    init(in directory: URL = .newTemporaryDirectory, signedInAs userId: Int? = nil) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = StockAlertDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            lookUpProducts: shop,
            store: FileStockAlertStore(directory: directory)
        )

        di.observeWaitlistUseCase()
            .sink { [weak self] in self?.alerts = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What the shop has

    func theCatalogStillSells(_ shelf: OnTheShelf...) {
        shop.stock = shelf
    }


    // MARK: - The two lists a shopper sees

    /// Still sold out, and still waited on.
    func stillWaitingFor() async -> [ProductID] {
        ((try? await di.getWaitlistProductsUseCase().get()) ?? []).map(\.id)
    }

    /// Asked about, and back on the shelf.
    func backInStock() async -> [ProductID] {
        ((try? await di.getBackInStockProductsUseCase().get()) ?? []).map(\.id)
    }

    // MARK: - What a shopper does

    @discardableResult
    func askToBeTold(aboutProductId productId: Int) async -> Result<Void, StockAlertError> {
        await di.setStockAlertForProductUseCase(productId: pid(productId), isOn: true)
    }

    @discardableResult
    func changeTheirMind(aboutProductId productId: Int) async -> Result<Void, StockAlertError> {
        await di.setStockAlertForProductUseCase(productId: pid(productId), isOn: false)
    }

    /// The bell on a product card, which watches one product and nothing else.
    func watchTheBell(onProductId productId: Int) {
        di.observeWaitlistStatusUseCase(productId: pid(productId))
            .sink { [weak self] in self?.bellIsRinging[pid(productId)] = $0 }
            .store(in: &cancellables)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    func leaveAndComeBack() -> Waiter {
        Waiter(in: directory, signedInAs: signedInUserId)
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

// MARK: - The session, which the alerts only ever read

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

    /// Somewhere the ask genuinely cannot be written: a directory that cannot be created, because
    /// the path it would sit under is a file.
    static func unwritableDirectory() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not a directory".utf8).write(to: file)
        return file.appending(path: "alerts", directoryHint: .isDirectory)
    }
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}


// MARK: - What the app cannot own


/// The catalog, which answers about what it still sells and says nothing about the rest.
final class StubCatalog: LookUpProductsUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var _stock: [OnTheShelf] = []

    var stock: [OnTheShelf] {
        get { lock.withLock { _stock } }
        set { lock.withLock { _stock = newValue } }
    }

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        lock.withLock {
            let wanted = Set(ids)
            return .success(_stock.filter { wanted.contains($0.id) }.map(\.product))
        }
    }
}

struct OnTheShelf {
    let product: Product

    var id: ProductID { product.id }
}

func inStock(_ id: Int) -> OnTheShelf {
    OnTheShelf(product: aProduct(id, availability: .inStock(remaining: 5)))
}

func soldOut(_ id: Int) -> OnTheShelf {
    OnTheShelf(product: aProduct(id, availability: .outOfStock))
}

private func aProduct(_ id: Int, availability: Availability) -> Product {
    Product(
        id: pid(id),
        title: "Product \(id)",
        description: "",
        category: CategoryID(rawValue: "beauty"),
        price: Money(amount: 9.99, currency: .usd),
        rating: 4.5,
        availability: availability,
        brand: "Acme",
        thumbnail: "https://cdn.example.com/\(id).png",
        images: []
    )
}
