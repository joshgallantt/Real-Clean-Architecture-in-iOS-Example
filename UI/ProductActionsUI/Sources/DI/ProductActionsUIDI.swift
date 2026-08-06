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
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase

    private let observeBagItemQuantity: ObserveBagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase

    private let observeWaitlistStatus: ObserveWaitlistStatusUseCase
    private let setStockAlertForProduct: SetStockAlertForProductUseCase

    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    public init(
        navigation: ProductActionsNavigation,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        observeBagItemQuantity: ObserveBagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        observeWaitlistStatus: ObserveWaitlistStatusUseCase,
        setStockAlertForProduct: SetStockAlertForProductUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.navigation = navigation
        self.observeProductIsWishlisted = observeProductIsWishlisted
        self.setProductIsWishlisted = setProductIsWishlisted
        self.observeBagItemQuantity = observeBagItemQuantity
        self.addItemToBag = addItemToBag
        self.observeWaitlistStatus = observeWaitlistStatus
        self.setStockAlertForProduct = setStockAlertForProduct
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

    /// The minus on a card that is already on the waitlist. Same use case as the bell, said the way
    /// a list needs it said.
    @MainActor
    public func removeFromWaitlistButton(productId: ProductID) -> some View {
        RemoveFromWaitlistButton(viewModel: makeStockAlertViewModel(productId: productId))
    }

    /// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: what the shop
    /// can supply decides which button a product gets, here, once. A single button that worked out
    /// what to be would be asked the question again on every render, and every caller would have to
    /// remember to ask it.
    ///
    @MainActor
    @ViewBuilder
    public func cardActionButton(product: Product) -> some View {
        switch product.availability {
        case .inStock:
            BagButtonView(viewModel: makeBagViewModel(product: product))
        case .outOfStock:
            StockAlertButtonView(viewModel: makeStockAlertViewModel(productId: product.id))
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
        }
    }

    // MARK: -

    @MainActor
    private func makeWishlistViewModel(productId: ProductID) -> WishlistButtonViewModel {
        WishlistButtonViewModel(
            productId: productId,
            observeProductIsWishlisted: observeProductIsWishlisted,
            setProductIsWishlisted: setProductIsWishlisted,
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
            observeWaitlistStatus: observeWaitlistStatus,
            setStockAlert: setStockAlertForProduct,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }
}
