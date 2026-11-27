import Combine
import SwiftUI
import Product
import Session
import Waitlist
import Wishlist
import AuthUI
import SnackbarUI
import WishlistUI
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
public struct WishlistUIDI {
    private let navigation: WishlistNavigation
    private let observeWishlist: ObserveWishlistUseCase
    private let observeWaitlist: ObserveWaitlistUseCase
    private let getStillSoldOutProducts: GetStillSoldOutProductsUseCase
    private let getBackInStockProducts: GetBackInStockProductsUseCase
    private let setProductIsWaitlisted: SetProductIsWaitlistedUseCase
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        observeWaitlist: ObserveWaitlistUseCase,
        getStillSoldOutProducts: GetStillSoldOutProductsUseCase,
        getBackInStockProducts: GetBackInStockProductsUseCase,
        setProductIsWaitlisted: SetProductIsWaitlistedUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.observeWaitlist = observeWaitlist
        self.getStillSoldOutProducts = getStillSoldOutProducts
        self.getBackInStockProducts = getBackInStockProducts
        self.setProductIsWaitlisted = setProductIsWaitlisted
        self.setProductIsWishlisted = setProductIsWishlisted
        self.lookUpProducts = lookUpProducts
        self.observeSession = observeSession
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.productActionsUIDI = productActionsUIDI
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
                authPresenter: authPresenter,
                trackScreenView: trackScreenView,
                trackElementInteraction: trackElementInteraction
            ),
            faves: favesViewModel(),
            waitlist: waitlistViewModel(),
            backInStock: backInStockViewModel(),
            navigation: navigation,
            waitlistAccessories: waitlistAccessories(),
            backInStockAccessories: backInStockAccessories(),
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

    @MainActor
    public func allWaitlistView() -> some View {
        alertedList(
            viewModel: waitlistViewModel(),
            accessories: waitlistAccessories(),
            listContext: WishlistTrackingPlan.waitlist,
            title: "Waitlist",
            emptyTitle: "Nothing to Wait For",
            emptyIcon: "bell",
            emptyMessage: "Hit the bell on anything sold out and it waits here."
        )
        .trackingScreen(WishlistTrackingPlan.waitlistScreen)
    }

    @MainActor
    public func allBackInStockView() -> some View {
        alertedList(
            viewModel: backInStockViewModel(),
            accessories: backInStockAccessories(),
            listContext: WishlistTrackingPlan.backInStock,
            title: "Back in Stock",
            emptyTitle: "Nothing Back Yet",
            emptyIcon: "sparkles",
            emptyMessage: "Anything you're waiting on lands here the second it's back."
        )
        .trackingScreen(WishlistTrackingPlan.backInStockScreen)
    }

    // MARK: -

    /// A waitlist card is out of stock, so there is nothing to put in a bag from it. All it offers
    /// is taking it off the list.
    @MainActor
    private func waitlistAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { _ in AnyView(EmptyView()) },
            trailing: { product in AnyView(self.removeFromWaitlistButton(product: product)) }
        )
    }

    /// Back in stock, so the bag button is the point of it — and the minus sits where the minus
    /// sits on the list above, because it means the same thing in both.
    @MainActor
    private func backInStockAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { product in AnyView(self.productActionsUIDI.cardActionButton(product: product)) },
            trailing: { product in AnyView(self.removeFromWaitlistButton(product: product)) }
        )
    }

    @MainActor
    private func favesAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { product in AnyView(self.productActionsUIDI.cardActionButton(product: product)) },
            trailing: { product in AnyView(self.button(product: product)) }
        )
    }

    @MainActor
    private func removeFromWaitlistButton(product: Product) -> some View {
        productActionsUIDI.removeFromWaitlistButton(product: product)
    }

    @MainActor
    private func alertedList(
        viewModel: @autoclosure @escaping () -> AlertedProductsViewModel,
        accessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
        listContext: TrackingContext.List,
        title: String,
        emptyTitle: String,
        emptyIcon: String,
        emptyMessage: String
    ) -> some View {
        AlertedProductsListView(
            viewModel: viewModel(),
            title: title,
            emptyTitle: emptyTitle,
            emptyIcon: emptyIcon,
            emptyMessage: emptyMessage,
            listContext: listContext,
            accessory: accessories.trailing,
            leadingAccessory: accessories.leading
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
            couldNotLoad: "Faves Won't Load",
            list: WishlistTrackingPlan.faves,
            openProduct: { [navigation] product in navigation.openProductDetails(product: product) },
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            clear: { [setProductIsWishlisted] ids in
                for id in ids { await setProductIsWishlisted(productId: id, isWishlisted: false) }
            }
        )
    }

    /// Which products are on which list is the domain's to say, and it says so by name. This picks
    /// a use case; it does not sieve one list into two, which is what it used to do and what put a
    /// rule about stock inside a DI container.
    @MainActor
    private func waitlistViewModel() -> AlertedProductsViewModel {
        alertedProducts(
            from: { [getStillSoldOutProducts] in await getStillSoldOutProducts() },
            couldNotLoad: "Waitlist Won't Load",
            list: WishlistTrackingPlan.waitlist
        )
    }

    @MainActor
    private func backInStockViewModel() -> AlertedProductsViewModel {
        alertedProducts(
            from: { [getBackInStockProducts] in await getBackInStockProducts() },
            couldNotLoad: "That List Won't Load",
            list: WishlistTrackingPlan.backInStock
        )
    }

    @MainActor
    private func alertedProducts(
        from load: @escaping @MainActor () async -> Result<[Product], WaitlistError>,
        couldNotLoad: String,
        list: TrackingContext.List
    ) -> AlertedProductsViewModel {
        AlertedProductsViewModel(
            load: load,
            changes: { [observeWaitlist] in observeWaitlist() },
            clear: { [setProductIsWaitlisted] ids in
                for id in ids { _ = await setProductIsWaitlisted(productId: id, isWaitlisted: false) }
            },
            snackbar: snackbarPresenter,
            couldNotLoad: couldNotLoad,
            list: list,
            openProduct: { [navigation] product in navigation.openProductDetails(product: product) },
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction
        )
    }
}
