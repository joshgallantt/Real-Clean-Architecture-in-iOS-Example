public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: Int)
}

public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: Int) {
        repository.add(productId: productId)
    }
}
