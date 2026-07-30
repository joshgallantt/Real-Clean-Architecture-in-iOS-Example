import Combine
import Product

public protocol ObserveBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never>
}

public struct DefaultObserveBagItemQuantityUseCase: ObserveBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    /// Only this one product's count, and only when it actually changes — a badge on a
    /// product tile has no interest in the rest of the bag moving around it.
    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> {
        repository.bagPublisher
            .map { $0.quantity(of: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
