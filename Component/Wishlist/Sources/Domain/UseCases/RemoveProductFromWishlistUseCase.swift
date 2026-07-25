import Session

public protocol RemoveProductFromWishlistUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: Int) async -> Result<Void, WishlistError>
}

public struct DefaultRemoveProductFromWishlistUseCase: RemoveProductFromWishlistUseCase {
    private let repository: WishlistRepository
    private let userIsLoggedIn: UserIsLoggedInUseCase

    public init(repository: WishlistRepository, userIsLoggedIn: UserIsLoggedInUseCase) {
        self.repository = repository
        self.userIsLoggedIn = userIsLoggedIn
    }

    @MainActor
    @discardableResult
    public func callAsFunction(productId: Int) async -> Result<Void, WishlistError> {
        guard await userIsLoggedIn() else {
            return .failure(.unauthenticated)
        }
        repository.remove(productId: productId)
        return .success(())
    }
}
