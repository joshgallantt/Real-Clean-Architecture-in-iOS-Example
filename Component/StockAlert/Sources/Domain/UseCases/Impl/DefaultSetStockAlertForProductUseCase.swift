import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: being told when something returns
/// needs somewhere to tell them, which a guest has not given. The alerts cannot decide that for
/// themselves — they need the session — so the rule lives here rather than on the aggregate.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both.
public struct DefaultSetStockAlertForProductUseCase: SetStockAlertForProductUseCase {
    private let repository: StockAlertRepository
    private let getSession: GetSessionUseCase

    public init(repository: StockAlertRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    @discardableResult
    public func callAsFunction(
        productId: ProductID,
        isOn: Bool
    ) async -> Result<Void, StockAlertError> {
        guard getSession().isLoggedIn else { return .failure(.unauthenticated) }

        let alerts = repository.alerts
        let updated = isOn
            ? alerts.adding(StockAlert(productId: productId))
            : alerts.removing(productId: productId)

        /// Nothing to write, nothing that can fail. Tapping a bell that is already on is not an
        /// error and must not be reported as one.
        guard updated != alerts else { return .success(()) }

        do {
            try await repository.save(updated)
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
