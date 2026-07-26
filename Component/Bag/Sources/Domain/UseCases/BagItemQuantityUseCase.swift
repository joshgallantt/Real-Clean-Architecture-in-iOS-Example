import Combine

public protocol BagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: Int) -> AnyPublisher<Int, Never>
}

public struct DefaultBagItemQuantityUseCase: BagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: Int) -> AnyPublisher<Int, Never> {
        repository.quantityPublisher(productId: productId)
    }
}
