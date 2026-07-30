import SwiftUI
import Product
import Wishlist
import AuthUI
import SnackbarUI
import SharedUI

public struct SharedUIDI {
    private let observeProductIsWishlisted: ObserveProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    public init(
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.observeProductIsWishlisted = observeProductIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func wishlistButton(productId: ProductID) -> some View {
        WishlistButtonView(
            viewModel: WishlistButtonViewModel(
                productId: productId,
                observeProductIsWishlisted: observeProductIsWishlisted,
                addProductToWishlist: addProductToWishlist,
                removeProductFromWishlist: removeProductFromWishlist,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter
            )
        )
    }
}
