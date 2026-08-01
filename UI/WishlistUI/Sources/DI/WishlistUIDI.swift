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
    private let observeWaitlist: ObserveWaitlistUseCase
    private let getWaitlistProducts: GetWaitlistProductsUseCase
    private let getBackInStockProducts: GetBackInStockProductsUseCase
    private let setStockAlertForProduct: SetStockAlertForProductUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let productActionsUIDI: ProductActionsUIDI

    public init(
        navigation: WishlistNavigation,
        observeWishlist: ObserveWishlistUseCase,
        observeWaitlist: ObserveWaitlistUseCase,
        getWaitlistProducts: GetWaitlistProductsUseCase,
        getBackInStockProducts: GetBackInStockProductsUseCase,
        setStockAlertForProduct: SetStockAlertForProductUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        productActionsUIDI: ProductActionsUIDI
    ) {
        self.navigation = navigation
        self.observeWishlist = observeWishlist
        self.observeWaitlist = observeWaitlist
        self.getWaitlistProducts = getWaitlistProducts
        self.getBackInStockProducts = getBackInStockProducts
        self.setStockAlertForProduct = setStockAlertForProduct
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
            session: WishlistScreenViewModel(observeSession: observeSession),
            faves: favesViewModel(),
            waitlist: waitlistViewModel(),
            backInStock: backInStockViewModel(),
            navigation: navigation,
            waitlistAccessories: waitlistAccessories(),
            backInStockAccessories: backInStockAccessories(),
            favesAccessories: favesAccessories(),
            authPresenter: authPresenter
        )
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
    }

    @MainActor
    public func allWaitlistView() -> some View {
        alertedList(
            viewModel: waitlistViewModel(),
            accessories: waitlistAccessories(),
            title: "Waitlist",
            emptyTitle: "Nothing to Wait For",
            emptyIcon: "bell",
            emptyMessage: "Hit the bell on anything sold out and it waits here."
        )
    }

    @MainActor
    public func allBackInStockView() -> some View {
        alertedList(
            viewModel: backInStockViewModel(),
            accessories: backInStockAccessories(),
            title: "Back in Stock",
            emptyTitle: "Nothing Back Yet",
            emptyIcon: "sparkles",
            emptyMessage: "Anything you're waiting on lands here the second it's back."
        )
    }

    // MARK: -

    /// A waitlist card is out of stock, so there is nothing to put in a bag from it. All it offers
    /// is taking it off the list.
    @MainActor
    private func waitlistAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { _ in AnyView(EmptyView()) },
            trailing: { product in AnyView(self.removeFromWaitlistButton(productId: product.id)) }
        )
    }

    /// Back in stock, so the bag button is the point of it — and the minus sits where the minus
    /// sits on the list above, because it means the same thing in both.
    @MainActor
    private func backInStockAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { product in AnyView(self.productActionsUIDI.cardActionButton(product: product)) },
            trailing: { product in AnyView(self.removeFromWaitlistButton(productId: product.id)) }
        )
    }

    @MainActor
    private func favesAccessories() -> (leading: (Product) -> AnyView, trailing: (Product) -> AnyView) {
        (
            leading: { product in AnyView(self.productActionsUIDI.cardActionButton(product: product)) },
            trailing: { product in AnyView(self.button(productId: product.id)) }
        )
    }

    @MainActor
    private func removeFromWaitlistButton(productId: ProductID) -> some View {
        productActionsUIDI.removeFromWaitlistButton(productId: productId)
    }

    @MainActor
    private func alertedList(
        viewModel: @autoclosure @escaping () -> AlertedProductsViewModel,
        accessories: (leading: (Product) -> AnyView, trailing: (Product) -> AnyView),
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
            onSelect: { [navigation] product in navigation.openProductDetails(product: product) },
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
            couldNotLoad: "Faves Won't Load",
            clear: { [removeProductFromWishlist] ids in
                for id in ids { _ = await removeProductFromWishlist(productId: id) }
            }
        )
    }

    /// Which products are on which list is the domain's to say, and it says so by name. This picks
    /// a use case; it does not sieve one list into two, which is what it used to do and what put a
    /// rule about stock inside a DI container.
    @MainActor
    private func waitlistViewModel() -> AlertedProductsViewModel {
        alertedProducts(from: { [getWaitlistProducts] in await getWaitlistProducts() }, couldNotLoad: "Waitlist Won't Load")
    }

    @MainActor
    private func backInStockViewModel() -> AlertedProductsViewModel {
        alertedProducts(from: { [getBackInStockProducts] in await getBackInStockProducts() }, couldNotLoad: "That List Won't Load")
    }

    @MainActor
    private func alertedProducts(
        from load: @escaping @MainActor () async -> Result<[Product], StockAlertError>,
        couldNotLoad: String
    ) -> AlertedProductsViewModel {
        AlertedProductsViewModel(
            load: load,
            changes: { [observeWaitlist] in observeWaitlist() },
            clear: { [setStockAlertForProduct] ids in
                for id in ids { _ = await setStockAlertForProduct(productId: id, isOn: false) }
            },
            snackbar: snackbarPresenter,
            couldNotLoad: couldNotLoad
        )
    }
}
