import Combine
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

public struct DefaultObserveProductIsWishlistedUseCase: ObserveProductIsWishlistedUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.wishlistPublisher
            .map { $0.contains(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
