import SwiftUI
import HomeUIDI
import SearchUIDI
import WishlistUIDI
import BagUIDI
import SharedUIDI
import AccountUIDI
import AuthUIDI
import OnboardingUIDI
import ProductUIDI
import SnackbarUIDI
import SheetUIDI
import SessionDI
import SessionData
import SearchHistoryDI
import SearchHistoryData
import WishlistDI
import BagDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the composition root. Every
/// concrete type in the app is named here and nowhere else, so swapping one is a change to this
/// file alone. Its length tracks feature count, not complexity.
///
/// Martin, Ch. 22 — The Clean Architecture: the outermost ring. Nothing inward knows it exists. Not
/// unit tested — it is wiring, with no behaviour of its own.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection, not a Service Locator: collaborators are handed in through initialisers
/// rather than looked up. `Catalog` arrives the same way, which is what lets a demo vary it
/// without this file knowing demos exist.
@MainActor
final class CompositionRoot {
    /// The graph the app runs on. Swap the right-hand side for a demo's — see
    /// `DemoCompositionRoot`. Both sides compile, so a demo cannot rot unnoticed and switching
    /// one on is never a matter of uncommenting code.
    static let shared = CompositionRoot(catalog: .live())

    // MARK: - Components
    let sessionDI: SessionDI
    let catalog: Catalog
    let searchHistoryDI: SearchHistoryDI
    let wishlistDI: WishlistDI
    let bagDI: BagDI

    // MARK: - Feature Navigation
    let navigator: Navigator
    let snackbarUIDI: SnackbarUIDI
    let sheetUIDI: SheetUIDI

    // MARK: - UIDI Properties
    let onboardingUIDI: OnboardingUIDI
    let authUIDI: AuthUIDI
    let productUIDI: ProductUIDI
    let homeUIDI: HomeUIDI
    let searchUIDI: SearchUIDI
    let wishlistUIDI: WishlistUIDI
    let bagUIDI: BagUIDI
    let accountUIDI: AccountUIDI

    // MARK: - Views (created once to maintain state)
    let homeView: AnyView
    let searchView: AnyView
    let wishlistView: AnyView
    let bagView: AnyView
    let accountView: AnyView

    init(catalog: Catalog) {
        self.catalog = catalog

        // MARK: Component DI
        sessionDI = SessionDI(
            sessionStore: DefaultSessionStore(),
            authClient: FakeAuthClient(
                userStore: UserDefaultsUserStore(defaults: .standard),
                tokenLifetime: 60 * 60 * 24 * 7
            )
        )
        searchHistoryDI = SearchHistoryDI(
            store: UserDefaultsSearchHistoryStore(defaults: .standard),
            getSession: sessionDI.getSessionUseCase
        )
        wishlistDI = WishlistDI(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase,
        )
        bagDI = BagDI(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase
        )

        // MARK: Snackbars
        let snackbarDI = SnackbarUIDI()
        self.snackbarUIDI = snackbarDI

        // MARK: Sheet presentation
        let sheetDI = SheetUIDI()
        self.sheetUIDI = sheetDI

        // MARK: UI Features
        onboardingUIDI = OnboardingUIDI()
        let authDI = AuthUIDI(
            loginUseCase: sessionDI.loginUseCase,
            createAccountUseCase: sessionDI.createAccountUseCase,
            getSessionUseCase: sessionDI.getSessionUseCase,
            sheetPresenting: sheetDI.presenter
        )
        authUIDI = authDI

        // MARK: Navigation
        navigator = Navigator(authPresenter: authDI.presenter)

        let sharedUI = SharedUIDI(
            observeProductIsWishlisted: wishlistDI.observeProductIsWishlistedUseCase,
            addProductToWishlist: wishlistDI.addProductToWishlistUseCase,
            removeProductFromWishlist: wishlistDI.removeProductFromWishlistUseCase,
            authPresenter: authDI.presenter,
            snackbarPresenter: snackbarDI.presenter
        )

        let bagUI = BagUIDI(
            navigation: navigator,
            observeBag: bagDI.observeBagUseCase,
            observeBagChanges: bagDI.observeBagChangesUseCase,
            observeBagItemQuantity: bagDI.observeBagItemQuantityUseCase,
            addItemToBag: bagDI.addItemToBagUseCase,
            setBagItemQuantity: bagDI.setBagItemQuantityUseCase,
            lookUpProducts: catalog.lookUpProducts,
            bringBagUpToDate: bagDI.bringBagUpToDateUseCase,
            acknowledgeBagChange: bagDI.acknowledgeBagChangeUseCase,
            snackbarPresenter: snackbarDI.presenter,
            wishlistButton: { id in AnyView(sharedUI.wishlistButton(productId: id)) }
        )
        bagUIDI = bagUI
        let wishlistUI = WishlistUIDI(
            navigation: navigator,
            observeWishlist: wishlistDI.observeWishlistUseCase,
            lookUpProducts: catalog.lookUpProducts,
            observeSession: sessionDI.observeSessionUseCase,
            authPresenter: authDI.presenter,
            snackbarPresenter: snackbarDI.presenter,
            bagUIDI: bagUI,
            sharedUIDI: sharedUI
        )
        wishlistUIDI = wishlistUI
        productUIDI = ProductUIDI(
            viewProduct: catalog.viewProduct,
            bagUIDI: bagUI,
            sharedUIDI: sharedUI
        )
        homeUIDI = HomeUIDI(
            navigation: navigator,
            browseCatalog: catalog.browseCatalog,
            snackbar: snackbarDI.presenter
        )
        searchUIDI = SearchUIDI(
            navigation: navigator,
            browseCatalog: catalog.browseCatalog,
            browseCategories: catalog.browseCategories,
            getSearchHistory: searchHistoryDI.getSearchHistoryUseCase,
            recordSearch: searchHistoryDI.recordSearchUseCase,
            clearSearchHistory: searchHistoryDI.clearSearchHistoryUseCase,
            snackbarPresenter: snackbarDI.presenter,
            wishlistUIDI: wishlistUI,
            bagUIDI: bagUI
        )
        accountUIDI = AccountUIDI(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            logoutUseCase: sessionDI.logoutUseCase,
            authUIDI: authDI
        )

        // MARK: Create views once to maintain state across tab switches
        homeView = AnyView(homeUIDI.mainView())
        searchView = AnyView(searchUIDI.mainView())
        wishlistView = AnyView(wishlistUIDI.mainView())
        bagView = AnyView(bagUIDI.mainView())
        accountView = AnyView(accountUIDI.mainView())
    }

    // MARK: - Root

    @MainActor
    func makeMainViewModel() -> MainViewModel {
        MainViewModel(getSession: sessionDI.getSessionUseCase)
    }
}
