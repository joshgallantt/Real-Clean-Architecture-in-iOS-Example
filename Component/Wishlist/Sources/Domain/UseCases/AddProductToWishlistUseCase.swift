import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: requiring a signed-in shopper is
/// not something a wishlist can decide for itself — it needs the session — so the rule lives in the
/// use case rather than on the aggregate.
///
/// Evans, *Domain-Driven Design* (2003) — Aggregates: a rule spanning two aggregates belongs
/// outside both.
public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
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
        repository.save(repository.wishlist.adding(WishlistItem(productId: productId)))
        return .success(())
    }
}
