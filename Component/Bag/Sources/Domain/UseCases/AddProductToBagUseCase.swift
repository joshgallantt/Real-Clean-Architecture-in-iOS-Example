public protocol AddProductToBagUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, BagError>
}

public struct DefaultAddProductToBagUseCase: AddProductToBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, BagError> {
        repository.add(productId: productId)
        return .success(())
    }
}
