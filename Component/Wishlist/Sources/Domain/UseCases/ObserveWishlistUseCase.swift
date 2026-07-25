import Combine

public protocol ObserveWishlistUseCase: Sendable {
    @MainActor
    func execute() -> AnyPublisher<[WishlistItem], Never>
}

public struct DefaultObserveWishlistUseCase: ObserveWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func execute() -> AnyPublisher<[WishlistItem], Never> {
        repository.itemsPublisher
    }
}
