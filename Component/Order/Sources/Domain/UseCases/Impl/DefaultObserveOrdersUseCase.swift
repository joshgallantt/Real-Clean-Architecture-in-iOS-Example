import Combine

public struct DefaultObserveOrdersUseCase: ObserveOrdersUseCase {
    private let repository: OrderRepository

    public init(repository: OrderRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Orders, Never> {
        repository.ordersPublisher
    }
}
