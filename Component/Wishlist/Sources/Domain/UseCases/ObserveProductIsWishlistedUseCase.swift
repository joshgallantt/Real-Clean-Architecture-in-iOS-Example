import Combine
import Product

public protocol ObserveProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

public struct DefaultObserveProductIsWishlistedUseCase: ObserveProductIsWishlistedUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    /// Only whether this one product is saved, and only when that changes — a heart on
    /// a product tile has no interest in the rest of the list moving around it.
    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.wishlistPublisher
            .map { $0.contains(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
