public protocol RemoveProductFromBagUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, BagError>
}

public struct DefaultRemoveProductFromBagUseCase: RemoveProductFromBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, BagError> {
        repository.remove(productId: productId)
        return .success(())
    }
}
