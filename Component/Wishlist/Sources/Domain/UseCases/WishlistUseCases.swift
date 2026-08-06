import Combine
import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their wishlist. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}

public protocol ObserveProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Wishlist, Never>
}

public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}
