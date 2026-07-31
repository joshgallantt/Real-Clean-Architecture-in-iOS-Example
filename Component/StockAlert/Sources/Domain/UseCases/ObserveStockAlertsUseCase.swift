import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol ObserveStockAlertsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<StockAlerts, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: the whole list,
/// for a screen that shows the whole list. `ObserveWaitingForProductUseCase` answers about one
/// product because a bell on a tile has no interest in the rest; this exists because a screen
/// listing what a shopper is waiting for has no way to ask that question one product at a time.
public struct DefaultObserveStockAlertsUseCase: ObserveStockAlertsUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<StockAlerts, Never> {
        repository.alertsPublisher
    }
}
