import Combine

public protocol IsInWishlistUseCase: Sendable {
    @MainActor
    func execute(productId: Int) -> AnyPublisher<Bool, Never>
}

public struct DefaultIsInWishlistUseCase: IsInWishlistUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func execute(productId: Int) -> AnyPublisher<Bool, Never> {
        repository.isInWishlistPublisher(productId: productId)
    }
}
