import Combine
import Foundation
import Money
import Order
import OrderData
import OrderDI
import Product
import Session

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper bought and what they were shown afterwards, never which type held it.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over a real `FileOrderStore` in a temporary directory — real repository, real DTOs, real JSON on
/// a real disk. Only the processor is stood in for, because there is no real one to talk to.
final class Buyer {
    private let directory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: OrderDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var orders = Orders()

    init(
        in directory: URL = .newTemporaryDirectory,
        signedInAs userId: Int? = 1,
        theShopTakesPayment outcome: FakePaymentClient.Outcome = .succeeds
    ) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = OrderDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: FileOrderStore(directory: directory),
            payment: FakePaymentClient(outcome)
        )

        di.observeOrdersUseCase()
            .sink { [weak self] in self?.orders = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper does

    @discardableResult
    func buy(_ lines: OrderLine...) async -> Result<Order, OrderError> {
        await di.placeOrderUseCase(lines)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - Leaving and coming back

    /// The shopper closes the app and opens it again. Waits for what they bought to reach the disk
    /// first, so a journey that ends here is asserting what was *kept*, not what was still in
    /// flight.
    func leaveAndComeBack() async -> Buyer {
        await writesToSettle()
        return Buyer(in: directory, signedInAs: signedInUserId)
    }

    func writesToSettle() async {
        let onDisk = FileOrderStore(directory: directory)
        for _ in 0..<100 where onDisk.getOrders(for: signedInUserId.map(UserID.init(rawValue:))) != orders {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private var signedInUserId: Int? {
        guard case .authenticated(let user) = sessions.value else { return nil }
        return user.id.rawValue
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

// MARK: - The session, which orders only ever read

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

/// One line of an order, as a shopper would describe it: this many of that thing, at that price.
func item(_ id: Int, quantity: Int = 1, at price: Decimal) -> OrderLine {
    OrderLine(productId: pid(id), quantity: quantity, pricePaid: usd(price))
}
