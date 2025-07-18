//
//  AppNavigator+registerAllDestinations.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

extension AppNavigator {
    static func registerAllDestinations(using injector: Injector) {
        let appNavigator = injector.appNavigator

        appNavigator.register { (destination: HomeDestination) in
            injector.homeUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: FavoritesDestination) in
            injector.favoritesUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: CartDestination) in
            injector.cartUIDI.makeView(for: destination)
        }
    }
}
