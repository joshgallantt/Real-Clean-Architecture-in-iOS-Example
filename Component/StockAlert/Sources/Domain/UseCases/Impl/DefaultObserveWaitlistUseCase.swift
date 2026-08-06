import Combine
import Product

public struct DefaultObserveWaitlistStatusUseCase: ObserveWaitlistStatusUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.alertsPublisher
            .map { $0.waitingFor(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

public struct DefaultObserveWaitlistUseCase: ObserveWaitlistUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<StockAlerts, Never> {
        repository.alertsPublisher
    }
}
