import SwiftUI
import Wishlist
import AuthUI
import SnackbarUI
import SharedUI

public struct SharedUIDI {
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    public init(
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func wishlistButton(productId: Int) -> some View {
        WishlistButtonView(
            viewModel: WishlistButtonViewModel(
                productId: productId,
                productIsWishlisted: productIsWishlisted,
                addProductToWishlist: addProductToWishlist,
                removeProductFromWishlist: removeProductFromWishlist,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter
            )
        )
    }
}
