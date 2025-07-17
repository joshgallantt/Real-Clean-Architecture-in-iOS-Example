//
//  FavoritesNavigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation

final class FavoritesNavigator: FavoritesNavigation {
    private unowned let navigator: AppNavigator

    init(navigator: AppNavigator) {
        self.navigator = navigator
    }

    func openFavoritesDetail(id: UUID) {
        navigator.push(FavoritesDestination.detail(id: id), tab: .favorites)
    }

    func goToCartDetail(id: UUID) {
        navigator.push(CartDestination.detail(id: id), tab: .cart)
    }
}
