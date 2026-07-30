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
import Product
import ProductDI
import ProductData
import SearchHistoryDI
import SearchHistoryData
import WishlistDI
import BagDI
import Networking

@MainActor
final class Injector {
    static let shared = Injector()

    // MARK: - Components
    let sessionDI: SessionDI
    let productDI: ProductDI
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

    // Pure wiring for the whole app graph, so its length tracks feature count, not complexity.
    // swiftlint:disable:next function_body_length
    private init() {
        // MARK: Component DI
        sessionDI = SessionDI(
            sessionStore: DefaultSessionStore(),
            authClient: FakeAuthClient(
                userStore: UserDefaultsUserStore(defaults: .standard),
                tokenLifetime: 60 * 60 * 24 * 7
            )
        )
        productDI = ProductDI(client: DummyJSONProductClient(httpClient: URLSessionHTTPClient(session: .shared)))

        let browseCatalog: BrowseCatalogUseCase = productDI.browseCatalogUseCase
        let lookUpProducts: LookUpProductsUseCase = productDI.lookUpProductsUseCase
        let viewProduct: ViewProductUseCase = productDI.viewProductUseCase

        // DEMO ONLY. Comment out the three lines above and uncomment these to make the
        // shop change its mind, so reopening the bag shows the Changed section. See
        // DemoCatalog.swift for the script. Never commit this switched on.
        //
        // let browseCatalog: BrowseCatalogUseCase =
        //     DemoBrowseCatalogUseCase(wrapped: productDI.browseCatalogUseCase)
        // let lookUpProducts: LookUpProductsUseCase =
        //     DemoLookUpProductsUseCase(wrapped: productDI.lookUpProductsUseCase)
        // let viewProduct: ViewProductUseCase =
        //     DemoViewProductUseCase(wrapped: productDI.viewProductUseCase)
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
            lookUpProducts: lookUpProducts,
            bringBagUpToDate: bagDI.bringBagUpToDateUseCase,
            acknowledgeBagChange: bagDI.acknowledgeBagChangeUseCase,
            snackbarPresenter: snackbarDI.presenter,
            wishlistButton: { id in AnyView(sharedUI.wishlistButton(productId: id)) }
        )
        bagUIDI = bagUI
        let wishlistUI = WishlistUIDI(
            navigation: navigator,
            observeWishlist: wishlistDI.observeWishlistUseCase,
            lookUpProducts: lookUpProducts,
            observeSession: sessionDI.observeSessionUseCase,
            authPresenter: authDI.presenter,
            snackbarPresenter: snackbarDI.presenter,
            bagUIDI: bagUI,
            sharedUIDI: sharedUI
        )
        wishlistUIDI = wishlistUI
        productUIDI = ProductUIDI(
            viewProduct: viewProduct,
            bagUIDI: bagUI,
            sharedUIDI: sharedUI
        )
        homeUIDI = HomeUIDI(
            navigation: navigator,
            browseCatalog: browseCatalog,
            snackbar: snackbarDI.presenter
        )
        searchUIDI = SearchUIDI(
            navigation: navigator,
            browseCatalog: browseCatalog,
            browseCategories: productDI.browseCategoriesUseCase,
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
