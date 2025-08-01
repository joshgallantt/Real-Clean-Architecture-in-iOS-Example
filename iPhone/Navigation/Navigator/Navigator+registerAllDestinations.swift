//
//  Navigator+registerAllDestinations.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import HomeUIDI
import HomeUI
import WishlistUIDI
import WishlistUI
import CartUIDI
import CartUI

extension Navigator {
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
