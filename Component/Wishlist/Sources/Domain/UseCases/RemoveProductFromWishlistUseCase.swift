import Session

public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, WishlistError>
}

public struct DefaultRemoveProductFromWishlistUseCase: RemoveProductFromWishlistUseCase {
    private let repository: WishlistRepository
    private let requireAuthentication: RequireAuthenticationUseCase

    public init(repository: WishlistRepository, requireAuthentication: RequireAuthenticationUseCase) {
        self.repository = repository
        self.requireAuthentication = requireAuthentication
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, WishlistError> {
        guard await requireAuthentication() else {
            return .failure(.unauthenticated)
        }
        repository.remove(productId: productId)
        return .success(())
    }
}
