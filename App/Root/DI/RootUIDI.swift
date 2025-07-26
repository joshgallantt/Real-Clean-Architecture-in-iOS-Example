//
//  RootUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 19/07/2025.
//

import SwiftUI
import UserDomain
import LoginUIDI
import HomeUIDI
import WishlistUIDI
import CartUIDI

public struct RootUIDI {
    private let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol
    private let loginUIDI: LoginUIDI
    private let homeUIDI: HomeUIDI
    private let wishlistUIDI: WishlistUIDI
    private let cartUIDI: CartUIDI
    private let navigator: Navigator

    init(
        observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol,
        loginUIDI: LoginUIDI,
        homeUIDI: HomeUIDI,
        wishlistUIDI: WishlistUIDI,
        cartUIDI: CartUIDI,
        navigator: Navigator
    ) {
        self.observeUserIsLoggedInUseCase = observeUserIsLoggedInUseCase
        self.loginUIDI = loginUIDI
        self.homeUIDI = homeUIDI
        self.wishlistUIDI = wishlistUIDI
        self.cartUIDI = cartUIDI
        self.navigator = navigator
    }

    private func makeRootViewModel() -> RootScreenViewModel {
        RootScreenViewModel(observeUserLoggedIn: observeUserIsLoggedInUseCase)
    }

    private func makeLoginView() -> some View {
        loginUIDI.mainView()
    }

    private func makeTabView() -> some View {
        TabScreen(
            navigator: navigator,
            homeView: homeUIDI.mainView(),
            wishlistView: wishlistUIDI.mainView(),
            cartView: cartUIDI.mainView()
        )
    }

    func mainView() -> some View {
        RootScreenView(
            viewModel: makeRootViewModel(),
            loginView: makeLoginView(),
            tabView: makeTabView()
        )
    }
}
