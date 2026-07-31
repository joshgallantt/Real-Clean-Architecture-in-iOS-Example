import Combine
import Foundation
import Order
import OrderData
import Session

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It is
/// the only thing that knows the concrete types, so it is the only thing that has to change when one
/// is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct OrderDI {
    private let repository: OrderRepository

    public let placeOrderUseCase: PlaceOrderUseCase
    public let observeOrdersUseCase: ObserveOrdersUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        store: OrderStore = FileOrderStore(),
        payment: PaymentClient = FakePaymentClient()
    ) {
        /// Evans, *Domain-Driven Design* (2003), Ch. 14 — Bounded Context: turning a session into an
        /// owner happens here, once, at the wiring boundary.
        let repository = DefaultOrderRepository(
            store: store,
            owner: Self.owner(for: getSession()),
            ownerPublisher: observeSession()
                .map(Self.owner(for:))
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.repository = repository

        self.placeOrderUseCase = DefaultPlaceOrderUseCase(
            repository: repository,
            payment: payment,
            getSession: getSession
        )
        self.observeOrdersUseCase = DefaultObserveOrdersUseCase(repository: repository)
    }

    /// Evans, *Domain-Driven Design* (2003), Ch. 10 — Assertions: exhaustive over `Session`. `nil`
    /// is nobody to file an order under, not a guest with an empty list — which is the same reason
    /// `PlaceOrderUseCase` refuses a guest outright.
    private static func owner(for session: Session) -> UserID? {
        switch session {
        case .guest:
            nil
        case .authenticated(let user):
            user.id
        }
    }
}
