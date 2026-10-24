import Combine
import Product

public struct DefaultObserveProductIsWaitlistedUseCase: ObserveProductIsWaitlistedUseCase {
    private let repository: WaitlistRepository

    public init(repository: WaitlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.waitlistPublisher
            .map { $0.contains(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
