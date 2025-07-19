//
//  MainUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeDI

public struct MainUIDI {
    let navigator: AppNavigator
    let homeUIDI: HomeUIDI
    let favoritesUIDI: FavoritesUIDI
    let cartUIDI: CartUIDI

    init(
        navigator: AppNavigator,
        homeUIDI: HomeUIDI,
        favoritesUIDI: FavoritesUIDI,
        cartUIDI: CartUIDI,
    ) {
        self.navigator = navigator
        self.homeUIDI = homeUIDI
        self.favoritesUIDI = favoritesUIDI
        self.cartUIDI = cartUIDI
    }

    func mainView() -> some View {
        MainScreenView(
            navigator: navigator,
            homeView: { self.homeUIDI.mainView() },
            favoritesView: { self.favoritesUIDI.mainView() },
            cartView: { self.cartUIDI.mainView() }
        )
    }
}
