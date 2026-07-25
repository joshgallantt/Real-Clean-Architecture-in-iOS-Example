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
        // MARK: Navigation
        navigator = Navigator()

        // MARK: Component DI
        sessionDI = SessionDI(
            sessionStore: DefaultSessionStore(),
            authClient: DummyJSONAuthClient(httpClient: URLSessionHTTPClient(session: .shared), tokenLifetime: 30 * 60)
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

        // MARK: UI Features
        onboardingUIDI = OnboardingUIDI()
        let loginDI = LoginUIDI(loginUseCase: sessionDI.loginUseCase)
        loginUIDI = loginDI
        productUIDI = ProductUIDI(getProduct: productDI.getProductUseCase)
        let wishlistUI = WishlistUIDI(
            navigation: navigator,
            observeWishlist: wishlistDI.observeWishlistUseCase,
            isInWishlist: wishlistDI.isInWishlistUseCase,
            addToWishlist: wishlistDI.addToWishlistUseCase,
            removeFromWishlist: wishlistDI.removeFromWishlistUseCase,
            getProduct: productDI.getProductUseCase
        )
        wishlistUIDI = wishlistUI
        homeUIDI = HomeUIDI(
            navigation: navigator,
            getProducts: productDI.getProductsUseCase
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
            makeLoginView: { AnyView(loginDI.loginView()) }
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
