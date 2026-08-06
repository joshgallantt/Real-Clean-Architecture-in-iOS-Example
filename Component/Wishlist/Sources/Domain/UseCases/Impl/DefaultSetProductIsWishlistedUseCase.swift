import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: requiring a signed-in shopper is
/// not something a wishlist can decide for itself — it needs the session — so the rule lives in the
/// use case rather than on the aggregate.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both. Saving and unsaving differ only in which side-effect-free function of the
/// aggregate they reach for, and everything around that — who may do it, what a refused write
/// means — was written twice to say the same thing once.
public struct DefaultSetProductIsWishlistedUseCase: SetProductIsWishlistedUseCase {
    private let repository: WishlistRepository
    private let getSession: GetSessionUseCase

    public init(repository: WishlistRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    @discardableResult
    public func callAsFunction(
        productId: ProductID,
        isWishlisted: Bool
    ) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }

        let wishlist = repository.wishlist
        let updated = isWishlisted
            ? wishlist.adding(WishlistItem(productId: productId))
            : wishlist.removing(productId: productId)

        do {
            try await repository.save(updated)
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
