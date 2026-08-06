import Money
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces: checking out is
/// not a module, it is this. What a shopper is checking out — one product from its page, or
/// everything in their bag — is decided by whoever calls it, and the rule is the same either way.
public protocol PlaceOrderUseCase: Sendable {
    @MainActor
    func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError>
}

/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: "These use cases
/// orchestrate the flow of data to and from the entities." Three steps in order — may they, does it
/// go through, write it down — and no entity owns the sequence because no entity can see all three.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: behaviour belonging to no single
/// aggregate, holding no state.
public struct DefaultPlaceOrderUseCase: PlaceOrderUseCase {
    private let repository: OrderRepository
    private let payment: PaymentClient
    private let getSession: GetSessionUseCase

    public init(repository: OrderRepository, payment: PaymentClient, getSession: GetSessionUseCase) {
        self.repository = repository
        self.payment = payment
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError> {
        /// An order has to belong to somebody. That is not something the lines can decide for
        /// themselves — they need the session — so the rule lives here rather than on the aggregate.
        guard getSession().isLoggedIn else { return .failure(.unauthenticated) }

        guard let amount = Money.total(of: lines.map(\.lineTotal)) else {
            return .failure(.nothingToOrder)
        }

        switch await payment.pay(amount) {
        case .failure(let failure):
            return .failure(Self.reason(failure))

        case .success(let reference):
            let order = Order(lines: lines, paymentReference: reference)
            repository.save(order)
            return .success(order)
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the processor's
    /// vocabulary translated into the shop's at the boundary, so nothing above here learns what a
    /// payment gateway calls things.
    private static func reason(_ failure: PaymentFailure) -> OrderError {
        switch failure {
        case .declined: .paymentDeclined
        case .unavailable: .unavailable
        }
    }
}
