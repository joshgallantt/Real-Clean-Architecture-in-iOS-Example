import Product
import Session

public struct DefaultRemoveProductFromWishlistUseCase: RemoveProductFromWishlistUseCase {
    private let repository: WishlistRepository
    private let getSession: GetSessionUseCase

    public init(repository: WishlistRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }

        do {
            try await repository.save(repository.wishlist.removing(productId: productId))
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
