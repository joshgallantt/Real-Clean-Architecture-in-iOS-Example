import Combine
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Wishlist, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError>
}
