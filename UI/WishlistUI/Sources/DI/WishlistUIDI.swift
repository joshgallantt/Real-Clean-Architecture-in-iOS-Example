import Combine
import SwiftUI
import Product
import Session
import StockAlert
import Wishlist
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
    private let observeStockAlerts: ObserveStockAlertsUseCase
    private let catchUpOnStockAlerts: CatchUpOnStockAlertsUseCase
    private let stopBeingToldWhenBack: StopBeingToldWhenBackUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        observeStockAlerts: ObserveStockAlertsUseCase,
        catchUpOnStockAlerts: CatchUpOnStockAlertsUseCase,
        stopBeingToldWhenBack: StopBeingToldWhenBackUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.observeStockAlerts = observeStockAlerts
        self.catchUpOnStockAlerts = catchUpOnStockAlerts
        self.stopBeingToldWhenBack = stopBeingToldWhenBack
        self.removeProductFromWishlist = removeProductFromWishlist
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
            session: WishlistScreenViewModel(
                observeSession: observeSession,
                catchUpOnStockAlerts: catchUpOnStockAlerts
            ),
            faves: favesViewModel(),
            notifyMe: notifyMeViewModel(),
            backInStock: backInStockViewModel(),
            navigation: navigation,
            wishlistButton: { productId in AnyView(button(productId: productId)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) },
            authPresenter: authPresenter
        )
    }

    @MainActor
    public func allFavesView() -> some View {
        list(
            viewModel: favesViewModel(),
            title: "My Faves",
            emptyTitle: "No Saved Items",
            emptyIcon: "heart",
            emptyMessage: "Tap the heart on a product to save it here."
        )
    }

    @MainActor
    public func allNotifyMeView() -> some View {
        list(
            viewModel: notifyMeViewModel(),
            title: "Notify Me",
            emptyTitle: "Nothing to Wait For",
            emptyIcon: "bell",
            emptyMessage: "Tap the bell on anything that's sold out and it'll wait here."
        )
    }

    @MainActor
    public func allBackInStockView() -> some View {
        list(
            viewModel: backInStockViewModel(),
            title: "Back in Stock",
            emptyTitle: "Nothing Back Yet",
            emptyIcon: "sparkles",
            emptyMessage: "Anything you're waiting on shows up here the moment it returns."
        )
    }

    // MARK: -

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
            onSelect: { [navigation] product in navigation.openProductDetails(product: product) },
            accessory: { product in AnyView(button(productId: product.id)) },
            leadingAccessory: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring. A wishlist and a set of stock alerts become the one thing the list view model reads —
    /// ids, newest first — so neither aggregate is named above this file and one view model serves
    /// both.
    @MainActor
    private func favesViewModel() -> SavedProductsViewModel {
        SavedProductsViewModel(
            savedProductIds: { [observeWishlist] in
                observeWishlist().map { $0.items.map(\.productId) }.eraseToAnyPublisher()
            },
            lookUpProducts: lookUpProducts,
            snackbar: snackbarPresenter,
            couldNotLoad: "Couldn't Load Your Faves",
            clear: { [removeProductFromWishlist] ids in
                for id in ids { _ = await removeProductFromWishlist(productId: id) }
            }
        )
    }

    /// The same asks feed both lists. Which one a product appears on is decided by what the shop
    /// says about it now — still sold out, or back — so a shopper never has to have been told
    /// anything for the split to be right, and something that returns moves the moment it does.
    @MainActor
    private func notifyMeViewModel() -> SavedProductsViewModel {
        alertsViewModel(keeping: { !$0.availability.isAvailable }, couldNotLoad: "Couldn't Load Notify Me")
    }

    @MainActor
    private func backInStockViewModel() -> SavedProductsViewModel {
        alertsViewModel(keeping: { $0.availability.isAvailable }, couldNotLoad: "Couldn't Load Back in Stock")
    }

    @MainActor
    private func alertsViewModel(
        keeping: @escaping @MainActor (Product) -> Bool,
        couldNotLoad: String
    ) -> SavedProductsViewModel {
        SavedProductsViewModel(
            savedProductIds: { [observeStockAlerts] in
                observeStockAlerts().map { $0.alerts.map(\.productId) }.eraseToAnyPublisher()
            },
            lookUpProducts: lookUpProducts,
            snackbar: snackbarPresenter,
            couldNotLoad: couldNotLoad,
            keeping: keeping,
            clear: { [stopBeingToldWhenBack] ids in
                for id in ids { _ = await stopBeingToldWhenBack(productId: id) }
            }
        )
    }
}
