public protocol RemoveFromWishlistUseCase: Sendable {
    @MainActor
    func execute(productId: Int)
}

public struct DefaultRemoveFromWishlistUseCase: RemoveFromWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func execute(productId: Int) {
        repository.remove(productId: productId)
    }
}
