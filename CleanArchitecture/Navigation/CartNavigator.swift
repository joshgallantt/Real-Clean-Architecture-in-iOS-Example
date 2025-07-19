//
//  CartNavigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 16/07/2025.
//

import Foundation
import HomePresentation

final class CartNavigator: CartNavigation {
    private unowned let navigator: AppNavigator

    init(navigator: AppNavigator) {
        self.navigator = navigator
    }

    func openCartDetail(id: UUID) {
        navigator.push(CartDestination.detail(id: id), tab: .cart)
    }

    func openHomeDetail(id: UUID) {
        navigator.push(HomeDestination.detail(id: id), tab: .home)
    }
}
