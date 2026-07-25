public protocol AddToWishlistUseCase: Sendable {
    @MainActor
    func execute(productId: Int)
}

public struct DefaultAddToWishlistUseCase: AddToWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func execute(productId: Int) {
        repository.add(productId: productId)
    }
}
