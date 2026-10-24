import Session
import Wishlist

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol WishlistStore: Sendable {
    func getItems(for owner: UserID?) -> [WishlistItem]

    /// Throws when the list could not be kept. What went wrong is the store's business; that it
    /// did not happen is the domain's.
    func setItems(_ items: [WishlistItem], for owner: UserID?) async throws
}
