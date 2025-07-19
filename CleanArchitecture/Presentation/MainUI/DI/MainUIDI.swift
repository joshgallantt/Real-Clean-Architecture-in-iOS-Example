//
//  MainUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeDI
import WishlistDI

public struct MainUIDI {
    let navigator: AppNavigator
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    init(
        navigator: AppNavigator,
        homeUIDI: HomeUIDI,
        wishlistUIDI: WishlistUIDI,
        cartUIDI: CartUIDI,
    ) {
        self.navigator = navigator
        self.homeUIDI = homeUIDI
        self.wishlistUIDI = wishlistUIDI
        self.cartUIDI = cartUIDI
    }

    func mainView() -> some View {
        MainScreenView(
            navigator: navigator,
            homeView: { self.homeUIDI.mainView() },
            favoritesView: { self.wishlistUIDI.mainView() },
            cartView: { self.cartUIDI.mainView() }
        )
    }
}
