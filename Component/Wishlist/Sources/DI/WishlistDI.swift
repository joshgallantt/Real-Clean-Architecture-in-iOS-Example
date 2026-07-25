import Combine
import Foundation
import Wishlist
import WishlistData
import Session

public struct WishlistDI {
    private let repository: WishlistRepository

    public let observeWishlistUseCase: ObserveWishlistUseCase
    public let productIsWishlistedUseCase: ProductIsWishlistedUseCase
    public let addProductToWishlistUseCase: AddProductToWishlistUseCase
    public let removeProductFromWishlistUseCase: RemoveProductFromWishlistUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        userIsLoggedIn: UserIsLoggedInUseCase,
        store: WishlistStore = UserDefaultsWishlistStore(defaults: .standard)
    ) {
        let repository = DefaultWishlistRepository(
            store: store,
            userKey: Self.userKey(for: getSession()),
            userKeyPublisher: observeSession().map(Self.userKey(for:)).eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeWishlistUseCase = DefaultObserveWishlistUseCase(repository: repository)
        self.productIsWishlistedUseCase = DefaultProductIsWishlistedUseCase(repository: repository)
        self.addProductToWishlistUseCase = DefaultAddProductToWishlistUseCase(repository: repository, userIsLoggedIn: userIsLoggedIn)
        self.removeProductFromWishlistUseCase = DefaultRemoveProductFromWishlistUseCase(repository: repository, userIsLoggedIn: userIsLoggedIn)
    }

    private static func userKey(for session: Session) -> String {
        session.user.map { String($0.id) } ?? "guest"
    }
}
