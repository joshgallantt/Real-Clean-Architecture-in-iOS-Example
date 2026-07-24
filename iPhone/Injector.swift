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
import SessionDI
import SessionData
import ProductDI
import ProductData
import SearchDI
import SearchData
import Networking

@MainActor
final class Injector {
    static let shared = Injector()

    // MARK: - Components
    let sessionDI: SessionDI
    let productDI: ProductDI
    let searchDI: SearchDI

    // MARK: - Feature Navigation
    let navigator: Navigator

    // MARK: - UIDI Properties
    let onboardingUIDI: OnboardingUIDI
    let loginUIDI: LoginUIDI
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
    let loginView: AnyView

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

        // MARK: UI Features
        onboardingUIDI = OnboardingUIDI()
        loginUIDI = LoginUIDI(loginUseCase: sessionDI.loginUseCase)
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
            clearSearchHistory: searchDI.clearSearchHistoryUseCase
        )
        wishlistUIDI = WishlistUIDI(navigation: navigator)
        bagUIDI = BagUIDI(navigation: navigator)
        accountUIDI = AccountUIDI(
            navigation: navigator,
            getSession: sessionDI.getSessionUseCase,
            observeSession: sessionDI.observeSessionUseCase,
            logoutUseCase: sessionDI.logoutUseCase
        )

        // MARK: Create views once to maintain state across tab switches
        homeView = AnyView(homeUIDI.mainView())
        searchView = AnyView(searchUIDI.mainView())
        wishlistView = AnyView(wishlistUIDI.mainView())
        bagView = AnyView(bagUIDI.mainView())
        accountView = AnyView(accountUIDI.mainView())
        loginView = AnyView(loginUIDI.loginView())
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
