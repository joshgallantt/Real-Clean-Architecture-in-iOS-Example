import Combine

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
