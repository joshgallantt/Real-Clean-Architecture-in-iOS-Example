import SwiftUI
import Bag
import Product
import StockAlert
import Wishlist
import AuthUI
import SnackbarUI
import Tracking
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

    private let observeBag: ObserveBagUseCase
    private let setBagItem: SetBagItemUseCase

    private let observeProductHasStockAlert: ObserveProductHasStockAlertUseCase
    private let setProductStockAlert: SetProductStockAlertUseCase

    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting

    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        navigation: ProductActionsNavigation,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        observeBag: ObserveBagUseCase,
        setBagItem: SetBagItemUseCase,
        observeProductHasStockAlert: ObserveProductHasStockAlertUseCase,
        setProductStockAlert: SetProductStockAlertUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.navigation = navigation
        self.observeProductIsWishlisted = observeProductIsWishlisted
        self.setProductIsWishlisted = setProductIsWishlisted
        self.observeBag = observeBag
        self.setBagItem = setBagItem
        self.observeProductHasStockAlert = observeProductHasStockAlert
        self.setProductStockAlert = setProductStockAlert
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    @MainActor
    public func wishlistButton(product: Product) -> some View {
        WishlistButtonView(viewModel: makeWishlistViewModel(product: product))
    }

    @MainActor
    public func stockAlertButton(product: Product) -> some View {
        StockAlertButtonView(viewModel: makeStockAlertViewModel(product: product))
    }

    /// The minus on a card the shopper already has an alert on. Same use case as the bell, said the way
    /// a list needs it said.
    @MainActor
    public func removeStockAlertButton(product: Product) -> some View {
        RemoveStockAlertButton(viewModel: makeStockAlertViewModel(product: product))
    }

    /// No button is told the screen it is drawn on. The same heart is on six of them, and where it is
    /// — a screen, or a position in a list on one — is in the environment it is drawn into.
    ///
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
            StockAlertButtonView(viewModel: makeStockAlertViewModel(product: product))
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
            NotifyMeButton(viewModel: makeStockAlertViewModel(product: product))
        }
    }

    // MARK: -

    @MainActor
    private func makeWishlistViewModel(product: Product) -> WishlistButtonViewModel {
        WishlistButtonViewModel(
            product: product,
            observeProductIsWishlisted: observeProductIsWishlisted,
            setProductIsWishlisted: setProductIsWishlisted,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            trackEvent: trackEvent
        )
    }

    @MainActor
    private func makeBagViewModel(product: Product) -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            observeBag: observeBag,
            setBagItem: setBagItem,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            trackEvent: trackEvent
        )
    }

    @MainActor
    private func makeStockAlertViewModel(product: Product) -> StockAlertButtonViewModel {
        StockAlertButtonViewModel(
            product: product,
            observeProductHasStockAlert: observeProductHasStockAlert,
            setProductStockAlert: setProductStockAlert,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction
        )
    }
}
