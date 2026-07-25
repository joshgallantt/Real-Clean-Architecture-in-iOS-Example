import Session

public protocol AddProductToWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, WishlistError>
}

public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
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
        repository.add(productId: productId)
        return .success(())
    }
}
