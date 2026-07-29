import Combine

/// Access to the shopper's wishlist, and nothing else. What saving or removing *means*
/// is the wishlist's own business, and deciding which to do is the use case's.
public protocol WishlistRepository: Sendable {
    @MainActor
    var wishlist: Wishlist { get }

    @MainActor
    var wishlistPublisher: AnyPublisher<Wishlist, Never> { get }

    @MainActor
    func save(_ wishlist: Wishlist)
}
