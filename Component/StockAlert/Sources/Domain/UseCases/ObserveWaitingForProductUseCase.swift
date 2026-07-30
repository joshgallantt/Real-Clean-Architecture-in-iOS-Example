import Combine
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveWaitingForProductUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

public struct DefaultObserveWaitingForProductUseCase: ObserveWaitingForProductUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    /// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: one product's
    /// answer, and only when it changes. A bell on a product tile has no interest in the rest of
    /// what the shopper is waiting on.
    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.alertsPublisher
            .map { $0.waitingFor(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
