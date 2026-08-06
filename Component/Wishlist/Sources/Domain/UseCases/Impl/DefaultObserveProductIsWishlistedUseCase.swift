import Combine
import Product

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
