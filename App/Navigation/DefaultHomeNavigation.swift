//
//  DefaultHomeNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation
import HomePresentation
import WishlistPresentation

final class DefaultHomeNavigation: HomeNavigation {
    private unowned let navigator: Navigator

    init(navigator: Navigator) {
        self.navigator = navigator
    }

    func openHomeDetail(id: UUID) {
        navigator.push(HomeDestination.detail(id: id), tab: .home)
    }

    func goToWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }
}
