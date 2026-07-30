import SwiftUI
import Wishlist
import Product
import Session
import AuthUI
import SnackbarUI
import WishlistUI
import ProductActionsUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.lookUpProducts = lookUpProducts
        self.observeSession = observeSession
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.productActionsUIDI = productActionsUIDI
    }

    @MainActor
    public func button(productId: ProductID) -> some View {
        productActionsUIDI.wishlistButton(productId: productId)
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            viewModel: WishlistScreenViewModel(
                observeWishlist: observeWishlist,
                lookUpProducts: lookUpProducts,
                observeSession: observeSession,
                snackbar: snackbarPresenter
            ),
            navigation: navigation,
            wishlistButton: { productId in AnyView(button(productId: productId)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) },
            authPresenter: authPresenter
        )
    }
}
