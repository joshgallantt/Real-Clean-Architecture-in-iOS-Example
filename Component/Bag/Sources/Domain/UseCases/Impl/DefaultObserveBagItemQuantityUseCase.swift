import Combine
import Product

public struct DefaultObserveBagItemQuantityUseCase: ObserveBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    /// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: one line's
    /// count, and only when it changes. A badge on a product tile has no interest in the rest of
    /// the bag.
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> {
        repository.bagPublisher
            .map { $0.quantity(of: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
