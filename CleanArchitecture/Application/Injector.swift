//
//  Injector.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeDI

final class Injector {
    static let shared = Injector()
    
    // MARK: - Components
    private let userDI: UserDI

    // MARK: - Feature Navigators
    let appNavigator: AppNavigator
    private let homeNavigator: HomeNavigator
    private let cartNavigator: CartNavigator
    private let favoritesNavigator: FavoritesNavigator

    // MARK: - UIDI Properties
    let bootUIDI: BootUIDI
    let loginUIDI: LoginUIDI
    let mainUIDI: MainUIDI
    let homeUIDI: HomeUIDI
    let favoritesUIDI: FavoritesUIDI
    let cartUIDI: CartUIDI

    private init() {
        // MARK: Navigation
        appNavigator = AppNavigator()
        homeNavigator = HomeNavigator(navigator: appNavigator)
        cartNavigator = CartNavigator(navigator: appNavigator)
        favoritesNavigator = FavoritesNavigator(navigator: appNavigator)
        
        // MARK: User Component DI
        let userRepository = DefaultUserRepository(
            session: UserSession(),
            authClient: FakeAuthClient()
        )
        userDI = UserDI(userRepository: userRepository)

        // MARK: UI
        bootUIDI = BootUIDI(
            observeUserIsLoggedInUseCase: userDI.observeUserIsLoggedInUseCase
        )
        loginUIDI = LoginUIDI(
            userLogin: userDI.userLoginUseCase
        )
        homeUIDI = HomeUIDI(
            navigation: homeNavigator
        )
        favoritesUIDI = FavoritesUIDI(
            navigation: favoritesNavigator
        )
        cartUIDI = CartUIDI(
            navigation: cartNavigator
        )
        mainUIDI = MainUIDI(
            navigator: appNavigator,
            homeUIDI: homeUIDI,
            favoritesUIDI: favoritesUIDI,
            cartUIDI: cartUIDI
        )
    }
    
}
