import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
public protocol WishlistRepository: Sendable {
    @MainActor
    var wishlist: Wishlist { get }

    @MainActor
    var wishlistPublisher: AnyPublisher<Wishlist, Never> { get }

    @MainActor
    func save(_ wishlist: Wishlist)
}
