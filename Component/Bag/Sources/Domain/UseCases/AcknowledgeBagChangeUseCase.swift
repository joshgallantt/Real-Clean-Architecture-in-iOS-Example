public protocol AcknowledgeBagChangeUseCase: Sendable {
    /// The shopper has seen what happened to this product.
    @MainActor
    func callAsFunction(productId: Int)
}

public struct DefaultAcknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: Int) {
        repository.save(
            bag: repository.bag,
            changes: repository.changes.acknowledging(productId: productId)
        )
    }
}
