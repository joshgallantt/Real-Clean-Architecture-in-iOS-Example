import Product
import Session

public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}

public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
    private let repository: WishlistRepository
    private let getSession: GetSessionUseCase

    public init(repository: WishlistRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    /// Needing a signed-in shopper is not something a wishlist can decide for itself —
    /// it needs the session — so the rule lives here rather than on the list.
    @MainActor
    @discardableResult
    public func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }
        repository.save(repository.wishlist.adding(WishlistItem(productId: productId)))
        return .success(())
    }
}
