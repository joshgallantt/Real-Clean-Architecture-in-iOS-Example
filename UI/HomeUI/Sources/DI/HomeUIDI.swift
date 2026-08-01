import SwiftUI
import HomeUI
import Product
import SnackbarUI
import WishlistUIDI
import ProductActionsUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase
    private let snackbar: SnackbarPresenting
    private let wishlistUIDI: WishlistUIDI
    private let productActionsUIDI: ProductActionsUIDI

    public init(
        navigation: HomeNavigation,
        browseCatalog: BrowseCatalogUseCase,
        browseCategories: BrowseCategoriesUseCase,
        snackbar: SnackbarPresenting,
        wishlistUIDI: WishlistUIDI,
        productActionsUIDI: ProductActionsUIDI
    ) {
        self.navigation = navigation
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
        self.snackbar = snackbar
        self.wishlistUIDI = wishlistUIDI
        self.productActionsUIDI = productActionsUIDI
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(
                browseCatalog: browseCatalog,
                browseCategories: browseCategories,
                navigation: navigation,
                snackbar: snackbar
            ),
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
    }
}
