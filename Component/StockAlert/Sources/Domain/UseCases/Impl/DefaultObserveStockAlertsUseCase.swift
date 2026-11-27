import Combine

public struct DefaultObserveStockAlertsUseCase: ObserveStockAlertsUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<StockAlerts, Never> {
        repository.stockAlertsPublisher
    }
}
