public protocol UpdateBagItemQuantityUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int, quantity: Int) async -> Result<Void, BagError>
}

public struct DefaultUpdateBagItemQuantityUseCase: UpdateBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int, quantity: Int) async -> Result<Void, BagError> {
        repository.updateQuantity(productId: productId, quantity: quantity)
        return .success(())
    }
}
