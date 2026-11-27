import Combine
import Foundation
import Product
import ProductTestSupport
import Session
import SessionTestSupport
import StockAlert
import StockAlertData
import StockAlertDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper did and what they were shown afterwards, never which type held it.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over a real `FileStockAlertStore` in a temporary directory.
final class Shopper {
    private let directory: URL
    private let legacyDirectory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: StockAlertDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var stockAlerts = StockAlerts()
    private(set) var bellIsOn: [ProductID: Bool] = [:]

    /// The one thing the app cannot own here: the catalog.
    let shop = FakeLookUpProductsUseCase()

    init(
        in directory: URL = .newTemporaryDirectory,
        legacyDirectory: URL = .newTemporaryDirectory,
        signedInAs userId: Int? = nil
    ) {
        self.directory = directory
        self.legacyDirectory = legacyDirectory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = StockAlertDI(
            getSession: StubGetSessionUseCase(sessions: sessions),
            observeSession: SpyObserveSessionUseCase(sessions: sessions),
            lookUpProducts: shop,
            store: FileStockAlertStore(directory: directory, legacyDirectory: legacyDirectory)
        )

        di.observeStockAlertsUseCase()
            .sink { [weak self] in self?.stockAlerts = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What the shop has

    func theShopSells(_ shelf: OnTheShelf...) {
        shop.stock = shelf
    }

    // MARK: - What a shopper is shown

    /// The products the shopper has alerts on, as the shop has them now — or that it could not say.
    func alertedProducts() async -> Result<[Product], StockAlertError> {
        await di.getStockAlertProductsUseCase()
    }

    /// The same, in the order shown. Nothing, where the shop could not say.
    func shown() async -> [ProductID] {
        await shownProducts().map(\.id)
    }

    /// The ones shown as still sold out.
    func shownAsSoldOut() async -> [ProductID] {
        await shownProducts().filter { !$0.availability.isAvailable }.map(\.id)
    }

    /// The ones shown as back on the shelf.
    func shownAsBack() async -> [ProductID] {
        await shownProducts().filter(\.availability.isAvailable).map(\.id)
    }

    private func shownProducts() async -> [Product] {
        guard case .success(let products) = await alertedProducts() else { return [] }
        return products
    }

    // MARK: - What a shopper does

    @discardableResult
    func setAlert(productId: Int) async -> Result<Void, StockAlertError> {
        await di.setProductStockAlertUseCase(productId: pid(productId), isOn: true)
    }

    @discardableResult
    func clearAlert(productId: Int) async -> Result<Void, StockAlertError> {
        await di.setProductStockAlertUseCase(productId: pid(productId), isOn: false)
    }

    /// The bell on a product card, which watches one product and nothing else.
    func watchTheBell(onProductId productId: Int) {
        di.observeProductHasStockAlertUseCase(productId: pid(productId))
            .sink { [weak self] in self?.bellIsOn[pid(productId)] = $0 }
            .store(in: &cancellables)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - Leaving and coming back

    /// No waiting for anything to settle: setting an alert is not done until it is kept, so by the
    /// time `setAlert` has returned there is nothing in flight to wait for.
    func leaveAndComeBack() -> Shopper {
        Shopper(in: directory, legacyDirectory: legacyDirectory, signedInAs: signedInUserId)
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

// MARK: - Fixtures

extension URL {
    static var newTemporaryDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    /// Somewhere the alerts genuinely cannot be written: a directory that cannot be created,
    /// because the path it would sit under is a file. A real failure rather than a fake store —
    /// the store under test is the one that ships.
    static func unwritableDirectory() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not a directory".utf8).write(to: file)
        return file.appending(path: "alerts", directoryHint: .isDirectory)
    }
}

extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}

func inStock(_ id: Int) -> OnTheShelf {
    OnTheShelf(product: .fixture(id: id, availability: .inStock(remaining: 5)))
}

func soldOut(_ id: Int) -> OnTheShelf {
    OnTheShelf(product: .fixture(id: id, availability: .outOfStock))
}
