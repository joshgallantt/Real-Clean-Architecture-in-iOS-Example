//
//  HomeNavigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation

final class HomeNavigator: HomeNavigation {
    private unowned let navigator: AppNavigator

    init(navigator: AppNavigator) {
        self.navigator = navigator
    }

    func openHomeDetail(id: UUID) {
        navigator.push(HomeDestination.detail(id: id), tab: .home)
    }

    func goToFavoritesDetail(id: UUID) {
        navigator.push(FavoritesDestination.detail(id: id), tab: .favorites)
    }
}
