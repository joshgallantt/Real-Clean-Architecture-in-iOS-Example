import Combine
import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their wishlist. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

public protocol ObserveProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Wishlist, Never>
}

/// One heart, with a state — the setter for what `ObserveProductIsWishlistedUseCase` reports, and
/// named to say so. It was two use cases, saving and unsaving, which is two ways of writing one
/// toggle: every caller had to hold both and pick between them, so the button that draws the heart
/// had to work out which of the two its own current state implied. Now a caller says what it wants
/// to be true and the domain works out what that takes.
public protocol SetProductIsWishlistedUseCase: Sendable {
    @discardableResult
    func callAsFunction(productId: ProductID, isWishlisted: Bool) async -> Result<Void, WishlistError>
}
