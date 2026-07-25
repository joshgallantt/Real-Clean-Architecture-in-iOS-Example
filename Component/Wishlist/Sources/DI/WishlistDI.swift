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
        store: WishlistStore = UserDefaultsWishlistStore(defaults: .standard)
    ) {
        let repository = DefaultWishlistRepository(
            store: store,
            getSession: getSession,
            observeSession: observeSession
        )
        self.repository = repository

        self.observeWishlistUseCase = DefaultObserveWishlistUseCase(repository: repository)
        self.productIsWishlistedUseCase = DefaultProductIsWishlistedUseCase(repository: repository)
        self.addProductToWishlistUseCase = DefaultAddProductToWishlistUseCase(repository: repository)
        self.removeProductFromWishlistUseCase = DefaultRemoveProductFromWishlistUseCase(repository: repository)
    }
}
