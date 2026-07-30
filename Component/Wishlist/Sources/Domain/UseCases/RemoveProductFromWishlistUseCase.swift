import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
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
    public func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }
        repository.save(repository.wishlist.removing(productId: productId))
        return .success(())
    }
}
