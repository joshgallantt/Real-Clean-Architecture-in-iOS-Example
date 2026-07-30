import SwiftUI
import Product
import Wishlist
import AuthUI
import SnackbarUI
import SharedUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
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
