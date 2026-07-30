import SwiftUI
import Bag
import Product
import StockAlert
import Wishlist
import AuthUI
import SnackbarUI
import ProductActionsUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds the buttons more than
/// one feature needs. A heart, a bag and a bell appear on product cards, on the details screen, in
/// search results, in the wishlist and in the bag — features that would otherwise have to depend on
/// each other simply to draw them.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct ProductActionsUIDI {
    private let navigation: ProductActionsNavigation

    private let observeProductIsWishlisted: ObserveProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase

    private let observeBagItemQuantity: ObserveBagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase

    private let observeWaitingForProduct: ObserveWaitingForProductUseCase
    private let askToBeToldWhenBack: AskToBeToldWhenBackUseCase
    private let stopBeingToldWhenBack: StopBeingToldWhenBackUseCase

    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    public init(
        navigation: ProductActionsNavigation,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        observeBagItemQuantity: ObserveBagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        observeWaitingForProduct: ObserveWaitingForProductUseCase,
        askToBeToldWhenBack: AskToBeToldWhenBackUseCase,
        stopBeingToldWhenBack: StopBeingToldWhenBackUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.navigation = navigation
        self.observeProductIsWishlisted = observeProductIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.observeBagItemQuantity = observeBagItemQuantity
        self.addItemToBag = addItemToBag
        self.observeWaitingForProduct = observeWaitingForProduct
        self.askToBeToldWhenBack = askToBeToldWhenBack
        self.stopBeingToldWhenBack = stopBeingToldWhenBack
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func wishlistButton(productId: ProductID) -> some View {
        WishlistButtonView(viewModel: makeWishlistViewModel(productId: productId))
    }

    @MainActor
    public func stockAlertButton(productId: ProductID) -> some View {
        StockAlertButtonView(viewModel: makeStockAlertViewModel(productId: productId))
    }

    /// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: what the shop
    /// can supply decides which button a product gets, here, once. A single button that worked out
    /// what to be would be asked the question again on every render, and every caller would have to
    /// remember to ask it.
    ///
    /// Nothing the shop has stopped selling reaches a card — `BrowseCatalogUseCase` does not return
    /// them — so `.discontinued` is a case that should not arrive. It offers nothing rather than
    /// offering something nobody can buy.
    @MainActor
    @ViewBuilder
    public func cardActionButton(product: Product) -> some View {
        switch product.availability {
        case .inStock:
            BagButtonView(viewModel: makeBagViewModel(product: product))
        case .outOfStock:
            StockAlertButtonView(viewModel: makeStockAlertViewModel(productId: product.id))
        case .discontinued:
            EmptyView()
        }
    }

    /// The same decision at full width, for the details screen.
    @MainActor
    @ViewBuilder
    public func detailsActionButton(product: Product) -> some View {
        switch product.availability {
        case .inStock:
            AddToBagButton(viewModel: makeBagViewModel(product: product))
        case .outOfStock:
            NotifyMeButton(viewModel: makeStockAlertViewModel(productId: product.id))
        case .discontinued:
            UnavailableButton()
        }
    }

    // MARK: -

    @MainActor
    private func makeWishlistViewModel(productId: ProductID) -> WishlistButtonViewModel {
        WishlistButtonViewModel(
            productId: productId,
            observeProductIsWishlisted: observeProductIsWishlisted,
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }

    @MainActor
    private func makeBagViewModel(product: Product) -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            observeBagItemQuantity: observeBagItemQuantity,
            addItemToBag: addItemToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
    }

    @MainActor
    private func makeStockAlertViewModel(productId: ProductID) -> StockAlertButtonViewModel {
        StockAlertButtonViewModel(
            productId: productId,
            observeWaitingForProduct: observeWaitingForProduct,
            askToBeTold: askToBeToldWhenBack,
            stopBeingTold: stopBeingToldWhenBack,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }
}
