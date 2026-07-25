import Foundation
import Wishlist
import WishlistData
import Session

public struct WishlistDI {
    private let repository: WishlistRepository

    public let observeWishlistUseCase: ObserveWishlistUseCase
    public let isInWishlistUseCase: IsInWishlistUseCase
    public let addToWishlistUseCase: AddToWishlistUseCase
    public let removeFromWishlistUseCase: RemoveFromWishlistUseCase

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
        self.isInWishlistUseCase = DefaultIsInWishlistUseCase(repository: repository)
        self.addToWishlistUseCase = DefaultAddToWishlistUseCase(repository: repository)
        self.removeFromWishlistUseCase = DefaultRemoveFromWishlistUseCase(repository: repository)
    }
}
