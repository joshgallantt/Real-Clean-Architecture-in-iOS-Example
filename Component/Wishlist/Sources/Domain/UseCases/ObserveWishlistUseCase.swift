import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Wishlist, Never>
}

public struct DefaultObserveWishlistUseCase: ObserveWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Wishlist, Never> {
        repository.wishlistPublisher
    }
}
