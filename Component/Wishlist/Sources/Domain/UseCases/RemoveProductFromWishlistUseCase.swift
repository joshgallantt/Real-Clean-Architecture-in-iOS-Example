import Session

public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, WishlistError>
}

public struct DefaultRemoveProductFromWishlistUseCase: RemoveProductFromWishlistUseCase {
    private let repository: WishlistRepository
    private let getSession: GetSessionUseCase

    public init(repository: WishlistRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }
        repository.save(repository.wishlist.removing(productId: productId))
        return .success(())
    }
}
