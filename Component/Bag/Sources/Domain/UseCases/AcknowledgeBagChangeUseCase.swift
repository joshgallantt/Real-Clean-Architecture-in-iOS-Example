import Product

public protocol AcknowledgeBagChangeUseCase: Sendable {
    /// The shopper has seen what happened to this product.
    @MainActor
    func callAsFunction(productId: ProductID)
}

public struct DefaultAcknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) {
        repository.save(
            bag: repository.bag,
            changes: repository.changes.acknowledging(productId: productId)
        )
    }
}
