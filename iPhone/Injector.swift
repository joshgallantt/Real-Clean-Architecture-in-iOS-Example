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
import LoginUIDI
import OnboardingUIDI
import ProductUIDI
import SnackbarUI
import SessionDI
import SessionData
import ProductDI
import ProductData
import SearchDI
import SearchData
import WishlistDI
import Networking

@MainActor
final class Injector {
    static let shared = Injector()

    // MARK: - Components
    let sessionDI: SessionDI
    let productDI: ProductDI
    let searchDI: SearchDI
    let wishlistDI: WishlistDI

    // MARK: - Feature Navigation
    let navigator: Navigator
    let authGate: DefaultAuthGate
    let snackbarPresenter: SnackbarPresenter

    // MARK: - UIDI Properties
    let onboardingUIDI: OnboardingUIDI
    let loginUIDI: LoginUIDI
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
            observeSession: sessionDI.observeSessionUseCase
        )

        // MARK: Auth gate
        let authGate = DefaultAuthGate(getSession: sessionDI.getSessionUseCase)
        self.authGate = authGate

        // MARK: Snackbars
        let snackbarPresenter = SnackbarPresenter()
        self.snackbarPresenter = snackbarPresenter

        // MARK: Navigation
        navigator = Navigator(authGate: authGate)

        // MARK: UI Features
        onboardingUIDI = OnboardingUIDI()
        let loginDI = LoginUIDI(
            loginUseCase: sessionDI.loginUseCase,
            createAccountUseCase: sessionDI.createAccountUseCase
        )
        loginUIDI = loginDI
        productUIDI = ProductUIDI(getProduct: productDI.getProductUseCase)
        let wishlistUI = WishlistUIDI(
            navigation: navigator,
            observeWishlist: wishlistDI.observeWishlistUseCase,
            productIsWishlisted: wishlistDI.productIsWishlistedUseCase,
            addProductToWishlist: wishlistDI.addProductToWishlistUseCase,
            removeProductFromWishlist: wishlistDI.removeProductFromWishlistUseCase,
            getProduct: productDI.getProductUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            authGate: authGate,
            snackbar: snackbarPresenter
        )
        wishlistUIDI = wishlistUI
        homeUIDI = HomeUIDI(
            navigation: navigator,
            getProducts: productDI.getProductsUseCase,
            snackbar: snackbarPresenter
        )
        searchUIDI = SearchUIDI(
            navigation: navigator,
            getProducts: productDI.getProductsUseCase,
            getCategories: productDI.getCategoriesUseCase,
            getSearchHistory: searchDI.getSearchHistoryUseCase,
            recordSearch: searchDI.recordSearchUseCase,
            clearSearchHistory: searchDI.clearSearchHistoryUseCase,
            makeWishlistButton: { id in AnyView(wishlistUI.button(productId: id)) }
        )
        bagUIDI = BagUIDI(navigation: navigator)
        accountUIDI = AccountUIDI(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            logoutUseCase: sessionDI.logoutUseCase,
            authGate: authGate
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
        MainViewModel(
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase
        )
    }
}
