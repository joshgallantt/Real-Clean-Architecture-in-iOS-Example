//
//  DefaultWishlistNavigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation
import WishlistPresentation
import CartPresentation

final class DefaultWishlistNavigation: WishlistNavigation {
    private unowned let navigator: Navigator

    init(navigator: Navigator) {
        self.navigator = navigator
    }

    func openWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }

    func goToCartDetail(id: UUID) {
        navigator.push(CartDestination.detail(id: id), tab: .cart)
    }
}
