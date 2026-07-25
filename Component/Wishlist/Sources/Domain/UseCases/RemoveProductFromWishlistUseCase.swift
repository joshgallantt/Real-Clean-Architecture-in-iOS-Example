public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: Int)
}

public struct DefaultRemoveProductFromWishlistUseCase: RemoveProductFromWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: Int) {
        repository.remove(productId: productId)
    }
}
