import Combine

public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<[WishlistItem], Never>
}

public struct DefaultObserveWishlistUseCase: ObserveWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<[WishlistItem], Never> {
        repository.itemsPublisher
    }
}
