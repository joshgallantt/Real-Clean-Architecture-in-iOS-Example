//
//  Injector.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeUIDI
import SearchUIDI
import WishlistUIDI
import BagUIDI
import AccountUIDI
import AuthUIDI
import OnboardingUIDI
import ProductUIDI
import SnackbarUIDI
import SheetUIDI
import SessionDI
import SessionData
import ProductDI
import ProductData
import SearchDI
import SearchData
import WishlistDI
import BagDI
import Networking

@MainActor
final class Injector {
    static let shared = Injector()

    // MARK: - Components
    let sessionDI: SessionDI
    let productDI: ProductDI
    let searchDI: SearchDI
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
        searchDI = SearchDI(
            store: UserDefaultsSearchHistoryStore(defaults: .standard),
            getSession: sessionDI.getSessionUseCase
        )
        wishlistDI = WishlistDI(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            userIsLoggedIn: sessionDI.userIsLoggedInUseCase
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
            userIsLoggedInUseCase: sessionDI.userIsLoggedInUseCase,
            getSessionUseCase: sessionDI.getSessionUseCase,
            sheetPresenting: sheetDI.presenter
        )
        authUIDI = authDI

        // MARK: Navigation
        navigator = Navigator(authPresenter: authDI.presenter)

        let bagUI = BagUIDI(
            navigation: navigator,
            observeBag: bagDI.observeBagUseCase,
            bagItemQuantity: bagDI.bagItemQuantityUseCase,
            addProductToBag: bagDI.addProductToBagUseCase,
            removeProductFromBag: bagDI.removeProductFromBagUseCase,
            updateBagItemQuantity: bagDI.updateBagItemQuantityUseCase,
            getProductsByIds: productDI.getProductsByIdsUseCase,
            snackbarPresenter: snackbarDI.presenter
        )
        bagUIDI = bagUI
        productUIDI = ProductUIDI(getProduct: productDI.getProductUseCase, bagUIDI: bagUI)
        let wishlistUI = WishlistUIDI(
            navigation: navigator,
            observeWishlist: wishlistDI.observeWishlistUseCase,
            productIsWishlisted: wishlistDI.productIsWishlistedUseCase,
            addProductToWishlist: wishlistDI.addProductToWishlistUseCase,
            removeProductFromWishlist: wishlistDI.removeProductFromWishlistUseCase,
            getProductsByIds: productDI.getProductsByIdsUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            authPresenter: authDI.presenter,
            snackbarPresenter: snackbarDI.presenter,
            bagUIDI: bagUI
        )
        wishlistUIDI = wishlistUI
        homeUIDI = HomeUIDI(
            navigation: navigator,
            getProducts: productDI.getProductsUseCase,
            snackbar: snackbarDI.presenter
        )
        searchUIDI = SearchUIDI(
            navigation: navigator,
            getProducts: productDI.getProductsUseCase,
            getCategories: productDI.getCategoriesUseCase,
            getSearchHistory: searchDI.getSearchHistoryUseCase,
            recordSearch: searchDI.recordSearchUseCase,
            clearSearchHistory: searchDI.clearSearchHistoryUseCase,
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
