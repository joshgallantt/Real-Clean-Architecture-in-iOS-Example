//
//  Navigation+registerAllDestinations.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import HomeUIDI
import HomePresentation
import WishlistUIDI
import WishlistPresentation
import CartUIDI
import CartPresentation

extension Navigation {
    static func registerAllDestinations(using injector: Injector) {
        let appNavigator = injector.appNavigator

        appNavigator.register { (destination: HomeDestination) in
            injector.homeUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: WishlistDestination) in
            injector.wishlistUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: CartDestination) in
            injector.cartUIDI.makeView(for: destination)
        }
    }
}
