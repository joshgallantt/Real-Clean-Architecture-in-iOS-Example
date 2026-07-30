import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces: a shopper who changes
/// their mind is doing something, not undoing something. It has its own name.
public protocol StopBeingToldWhenBackUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, StockAlertError>
}

public struct DefaultStopBeingToldWhenBackUseCase: StopBeingToldWhenBackUseCase {
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
            try await repository.save(repository.alerts.removing(productId: productId))
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
