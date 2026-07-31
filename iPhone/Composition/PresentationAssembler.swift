import SwiftUI
import BagDI
import OrderDI
import SearchHistoryDI
import SessionDI
import StockAlertDI
import WishlistDI
import AccountUIDI
import AuthUIDI
import BagUIDI
import OrderUIDI
import HomeUIDI
import OnboardingUIDI
import ProductUIDI
import SearchUIDI
import ProductActionsUIDI
import SheetUIDI
import SnackbarUIDI
import WishlistUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the third phase. Feature
/// containers are built here and the tab views with them, from use cases alone.
///
/// Martin, Ch. 10 — Interface Segregation Principle: what each feature container receives is the
/// individual use cases it calls. `DomainAssembler` is read here and handed on nowhere, so no
/// feature can reach a capability it did not ask for.
///
/// The order below is the graph's, not a preference: the sheet host exists before the auth flow
/// that presents on it, the auth flow before the navigator that gates on it, and the shared
/// wishlist button before the two features that render one.
@MainActor
struct PresentationAssembler {
    let navigator: Navigator
    let snackbar: SnackbarUIDI
    let sheet: SheetUIDI

    let onboarding: OnboardingUIDI
    let auth: AuthUIDI
    let productActions: ProductActionsUIDI
    let product: ProductUIDI
    let home: HomeUIDI
    let search: SearchUIDI
    let wishlist: WishlistUIDI
    let bag: BagUIDI
    let order: OrderUIDI
    let account: AccountUIDI

    /// Built once at startup. If `TabScreen` called `mainView()` on each render, SwiftUI would
    /// create a new view identity on every tab switch, destroying all `@State`, scroll positions
    /// and in-flight async tasks.
    let homeView: AnyView
    let searchView: AnyView
    let wishlistView: AnyView
    let bagView: AnyView
    let accountView: AnyView

    init(domain: DomainAssembler) {
        let session = domain.session
        let catalog = domain.catalog

        let snackbar = SnackbarUIDI()
        let sheet = SheetUIDI()
        self.snackbar = snackbar
        self.sheet = sheet

        onboarding = OnboardingUIDI()

        let auth = AuthUIDI(
            loginUseCase: session.loginUseCase,
            createAccountUseCase: session.createAccountUseCase,
            getSessionUseCase: session.getSessionUseCase,
            sheetPresenting: sheet.presenter
        )
        self.auth = auth

        let navigator = Navigator(authPresenter: auth.presenter)
        self.navigator = navigator

        let productActions = ProductActionsUIDI(
            navigation: navigator,
            observeProductIsWishlisted: domain.wishlist.observeProductIsWishlistedUseCase,
            addProductToWishlist: domain.wishlist.addProductToWishlistUseCase,
            removeProductFromWishlist: domain.wishlist.removeProductFromWishlistUseCase,
            observeBagItemQuantity: domain.bag.observeBagItemQuantityUseCase,
            addItemToBag: domain.bag.addItemToBagUseCase,
            observeWaitingForProduct: domain.stockAlerts.observeWaitingForProductUseCase,
            askToBeToldWhenBack: domain.stockAlerts.askToBeToldWhenBackUseCase,
            stopBeingToldWhenBack: domain.stockAlerts.stopBeingToldWhenBackUseCase,
            authPresenter: auth.presenter,
            snackbarPresenter: snackbar.presenter
        )
        self.productActions = productActions

        /// Before the bag and the product screen, because both are handed a button it builds.
        let order = OrderUIDI(
            placeOrder: domain.orders.placeOrderUseCase,
            observeOrders: domain.orders.observeOrdersUseCase,
            observeBag: domain.bag.observeBagUseCase,
            setBagItemQuantity: domain.bag.setBagItemQuantityUseCase,
            authPresenter: auth.presenter,
            snackbarPresenter: snackbar.presenter,
            sheetPresenter: sheet.presenter
        )
        self.order = order

        let bag = BagUIDI(
            navigation: navigator,
            observeBag: domain.bag.observeBagUseCase,
            observeNotices: domain.bag.observeNoticesUseCase,
            setBagItemQuantity: domain.bag.setBagItemQuantityUseCase,
            bringBagUpToDate: domain.bag.bringBagUpToDateUseCase,
            acknowledgeNotices: domain.bag.acknowledgeNoticesUseCase,
            stockAlertButton: { id in AnyView(productActions.stockAlertButton(productId: id)) },
            checkoutButton: { AnyView(order.checkoutButton()) }
        )
        self.bag = bag

        let wishlist = WishlistUIDI(
            navigation: navigator,
            observeWishlist: domain.wishlist.observeWishlistUseCase,
            observeStockAlerts: domain.stockAlerts.observeStockAlertsUseCase,
            catchUpOnStockAlerts: domain.stockAlerts.catchUpOnStockAlertsUseCase,
            lookUpProducts: catalog.lookUpProducts,
            observeSession: session.observeSessionUseCase,
            authPresenter: auth.presenter,
            snackbarPresenter: snackbar.presenter,
            productActionsUIDI: productActions
        )
        self.wishlist = wishlist

        product = ProductUIDI(
            viewProduct: catalog.viewProduct,
            productActionsUIDI: productActions,
            buyNowButton: { product in AnyView(order.buyNowButton(product: product)) }
        )
        home = HomeUIDI(
            navigation: navigator,
            browseCatalog: catalog.browseCatalog,
            snackbar: snackbar.presenter
        )
        let search = SearchUIDI(
            navigation: navigator,
            browseCatalog: catalog.browseCatalog,
            browseCategories: catalog.browseCategories,
            getSearchHistory: domain.searchHistory.getSearchHistoryUseCase,
            recordSearch: domain.searchHistory.recordSearchUseCase,
            clearSearchHistory: domain.searchHistory.clearSearchHistoryUseCase,
            snackbarPresenter: snackbar.presenter,
            wishlistUIDI: wishlist,
            productActionsUIDI: productActions
        )
        self.search = search

        let account = AccountUIDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            logoutUseCase: session.logoutUseCase,
            authUIDI: auth,
            /// The route, not the screen. `AccountUI` renders whatever row it is handed and never
            /// learns what an order is or which destination this is.
            ordersRow: AnyView(
                NavigationLink(value: Destination.orderHistory) {
                    Label("Your Orders", systemImage: "shippingbox")
                }
            )
        )
        self.account = account

        homeView = AnyView(home.mainView())
        searchView = AnyView(search.mainView())
        wishlistView = AnyView(wishlist.mainView())
        bagView = AnyView(bag.mainView())
        accountView = AnyView(account.mainView())
    }
}
