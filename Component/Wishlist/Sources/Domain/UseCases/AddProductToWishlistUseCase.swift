import Session

public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, WishlistError>
}

public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
    private let repository: WishlistRepository
    private let userIsLoggedIn: UserIsLoggedInUseCase

    public init(repository: WishlistRepository, userIsLoggedIn: UserIsLoggedInUseCase) {
        self.repository = repository
        self.userIsLoggedIn = userIsLoggedIn
    }

    /// Needing a signed-in shopper is not something a wishlist can decide for itself —
    /// it needs the session — so the rule lives here rather than on the list.
    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, WishlistError> {
        guard await userIsLoggedIn() else {
            return .failure(.unauthenticated)
        }
        repository.save(repository.wishlist.adding(WishlistItem(id: productId)))
        return .success(())
    }
}
