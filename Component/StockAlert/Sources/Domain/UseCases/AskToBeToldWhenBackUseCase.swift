import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol AskToBeToldWhenBackUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, StockAlertError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: telling a shopper when something
/// returns needs somewhere to tell them, which a guest has not given. That is not something the
/// alerts can decide for themselves — they need the session — so the rule lives in the use case
/// rather than on the aggregate.
///
/// Evans, *Domain-Driven Design* (2003) — Aggregates: a rule spanning two aggregates belongs
/// outside both.
public struct DefaultAskToBeToldWhenBackUseCase: AskToBeToldWhenBackUseCase {
    private let repository: StockAlertRepository
    private let getSession: GetSessionUseCase

    public init(repository: StockAlertRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction(productId: ProductID) async -> Result<Void, StockAlertError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }

        do {
            try await repository.save(repository.alerts.adding(StockAlert(productId: productId)))
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
