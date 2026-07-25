import Combine

public protocol ProductIsWishlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: Int) -> AnyPublisher<Bool, Never>
}

public struct DefaultProductIsWishlistedUseCase: ProductIsWishlistedUseCase {
    private let repository: WishlistRepository

    public init(repository: WishlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: Int) -> AnyPublisher<Bool, Never> {
        repository.isInWishlistPublisher(productId: productId)
    }
}
