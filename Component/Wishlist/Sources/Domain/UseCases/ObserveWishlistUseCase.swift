import Combine

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
