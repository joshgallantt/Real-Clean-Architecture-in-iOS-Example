import Combine
import Foundation
import Product
import Session
import StockAlert
import StockAlertData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct StockAlertDI {
    public let observeStockAlertsUseCase: ObserveStockAlertsUseCase
    public let observeProductHasStockAlertUseCase: ObserveProductHasStockAlertUseCase
    public let setProductStockAlertUseCase: SetProductStockAlertUseCase
    public let getStockAlertProductsUseCase: GetStockAlertProductsUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        lookUpProducts: LookUpProductsUseCase,
        store: StockAlertStore = FileStockAlertStore()
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once.
        let repository = DefaultStockAlertRepository(
            store: store,
            owner: Self.owner(for: getSession()),
            ownerPublisher: observeSession()
                .map(Self.owner(for:))
                .removeDuplicates()
                .eraseToAnyPublisher()
        )

        self.observeStockAlertsUseCase = DefaultObserveStockAlertsUseCase(repository: repository)
        self.observeProductHasStockAlertUseCase = DefaultObserveProductHasStockAlertUseCase(repository: repository)
        self.setProductStockAlertUseCase = DefaultSetProductStockAlertUseCase(
            repository: repository,
            getSession: getSession
        )
        self.getStockAlertProductsUseCase = DefaultGetStockAlertProductsUseCase(
            repository: repository,
            lookUpProducts: lookUpProducts
        )
    }

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session`. `nil` is the
    /// absence of anywhere to send a message, not a guest with an empty list — a guest has given
    /// nobody an address to tell.
    private static func owner(for session: Session) -> UserID? {
        switch session {
        case .guest:
            nil
        case .authenticated(let user):
            user.id
        }
    }
}
