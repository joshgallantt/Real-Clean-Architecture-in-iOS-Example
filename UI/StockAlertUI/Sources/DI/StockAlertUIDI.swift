import SwiftUI
import Product
import StockAlert
import SnackbarUI
import StockAlertUI
import ProductActionsUIDI
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct StockAlertUIDI {
    private let navigation: StockAlertNavigation
    private let getStockAlertProducts: GetStockAlertProductsUseCase
    private let observeStockAlerts: ObserveStockAlertsUseCase
    private let setProductStockAlert: SetProductStockAlertUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        navigation: StockAlertNavigation,
        getStockAlertProducts: GetStockAlertProductsUseCase,
        observeStockAlerts: ObserveStockAlertsUseCase,
        setProductStockAlert: SetProductStockAlertUseCase,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.navigation = navigation
        self.getStockAlertProducts = getStockAlertProducts
        self.observeStockAlerts = observeStockAlerts
        self.setProductStockAlert = setProductStockAlert
        self.snackbarPresenter = snackbarPresenter
        self.productActionsUIDI = productActionsUIDI
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
    }

    /// The alerts as a row, for the screen that hosts it. It has no screen of its own, so it is
    /// reported on whichever screen it is drawn into.
    @MainActor
    public func sectionView() -> some View {
        StockAlertSectionView(
            viewModel: viewModel(),
            accessory: removeButton,
            leadingAccessory: buyButton
        )
    }

    @MainActor
    public func allStockAlertsView() -> some View {
        StockAlertProductsListView(
            viewModel: viewModel(),
            emptyTitle: "No Stock Alerts",
            emptyIcon: "bell",
            emptyMessage: "Hit the bell on anything sold out and it waits here.",
            accessory: removeButton,
            leadingAccessory: buyButton
        )
        .trackingScreen(StockAlertTrackingPlan.screen)
    }

    // MARK: -

    /// The minus, on every card: clearing the alert means the same thing whether the product is
    /// back or not.
    @MainActor
    private func removeButton(product: Product) -> AnyView {
        AnyView(productActionsUIDI.removeStockAlertButton(product: product))
    }

    /// A way to buy, on the cards of products that are back. One still sold out gets nothing here:
    /// the peer container would hand back its bell, and the minus beside it already says the alert
    /// is on.
    @MainActor
    private func buyButton(product: Product) -> AnyView {
        product.availability.isAvailable
            ? AnyView(productActionsUIDI.cardActionButton(product: product))
            : AnyView(EmptyView())
    }

    @MainActor
    private func viewModel() -> StockAlertProductsViewModel {
        StockAlertProductsViewModel(
            getStockAlertProducts: getStockAlertProducts,
            observeStockAlerts: observeStockAlerts,
            setProductStockAlert: setProductStockAlert,
            navigation: navigation,
            snackbar: snackbarPresenter,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction
        )
    }
}
