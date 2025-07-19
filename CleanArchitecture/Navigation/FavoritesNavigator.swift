//
//  WishlistNavigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation
import WishlistPresentation
import CartPresentation

final class WishlistNavigator: WishlistNavigation {
    private unowned let navigator: AppNavigator

    init(navigator: AppNavigator) {
        self.navigator = navigator
    }

    func openWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }

    func goToCartDetail(id: UUID) {
        navigator.push(CartDestination.detail(id: id), tab: .cart)
    }
}
