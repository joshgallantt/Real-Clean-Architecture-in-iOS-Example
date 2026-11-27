import SwiftUI
import Product
import Session
import Settings
import Wishlist
import AuthUI
import SnackbarUI
import WishlistUI
import ProductActionsUIDI
import StockAlertUIDI
import Tracking
import TrackingUI

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
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let observeSetting: ObserveSettingUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI

    /// The peer container itself, rather than a finished `AnyView` from the composition root: the
    /// tab shows the shopper's stock alerts above the faves, and `Package.swift` breaks if that
    /// stops being true. Its use cases stay behind it — nothing of the stock alert domain reaches
    /// here.
    private let stockAlertUIDI: StockAlertUIDI
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        observeSetting: ObserveSettingUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI,
        stockAlertUIDI: StockAlertUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.setProductIsWishlisted = setProductIsWishlisted
        self.lookUpProducts = lookUpProducts
        self.observeSession = observeSession
        self.observeSetting = observeSetting
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.productActionsUIDI = productActionsUIDI
        self.stockAlertUIDI = stockAlertUIDI
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
    }

    /// The heart, for whichever screen draws it — Home and Search draw it too, and where it is drawn
    /// is in the environment it is drawn into.
    @MainActor
    public func button(product: Product) -> some View {
        productActionsUIDI.wishlistButton(product: product)
    }

    @MainActor
    public func mainView() -> some View {
        WishlistScreenView(
            session: WishlistScreenViewModel(
                observeSession: observeSession,
                observeSetting: observeSetting,
                authPresenter: authPresenter,
                trackScreenView: trackScreenView,
                trackElementInteraction: trackElementInteraction
            ),
            faves: favesViewModel(),
            navigation: navigation,
            stockAlertSection: AnyView(stockAlertUIDI.sectionView()),
            favesAccessories: favesAccessories()
        )
        .trackingScreen(WishlistTrackingPlan.screen)
    }

    @MainActor
    public func allFavesView() -> some View {
        list(
            viewModel: favesViewModel(),
            title: "My Faves",
            emptyTitle: "Nothing Saved Yet",
            emptyIcon: "heart",
            emptyMessage: "Tap the heart on anything you like the look of."
        )
        .trackingScreen(WishlistTrackingPlan.favesScreen)
    }

    // MARK: -

    @MainActor
    private func favesAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { product in AnyView(self.productActionsUIDI.cardActionButton(product: product)) },
            trailing: { product in AnyView(self.button(product: product)) }
        )
    }

    @MainActor
    private func list(
        viewModel: SavedProductsViewModel,
        title: String,
        emptyTitle: String,
        emptyIcon: String,
        emptyMessage: String
    ) -> some View {
        SavedProductsListView(
            viewModel: viewModel,
            title: title,
            emptyTitle: emptyTitle,
            emptyIcon: emptyIcon,
            emptyMessage: emptyMessage,
            listContext: WishlistTrackingPlan.faves,
            accessory: { product in AnyView(button(product: product)) },
            leadingAccessory: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
    }

    @MainActor
    private func favesViewModel() -> SavedProductsViewModel {
        SavedProductsViewModel(
            observeWishlist: observeWishlist,
            lookUpProducts: lookUpProducts,
            setProductIsWishlisted: setProductIsWishlisted,
            navigation: navigation,
            snackbar: snackbarPresenter,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            pageSize: 30
        )
    }
}
