//
//  Injector.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

final class Injector {
    static let shared = Injector()
    
    // MARK: - Component Properties
    
    // MARK: - User
    let userSession: UserSession
    let userRepository: UserRepository
    let userIsLoggedIn: UserIsLoggedInUseCase
    let observeUserIsLoggedIn: ObserveUserIsLoggedInUseCase
    let userLogin: UserLoginUseCase

    // MARK: - Feature Navigators
    let appNavigator: AppNavigator
    let homeNavigator: HomeNavigator
    let cartNavigator: CartNavigator
    let favoritesNavigator: FavoritesNavigator

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
        
        // MARK: Domain Component - User
        userSession = UserSession()
        userRepository = RealUserRepository(session: userSession, authClient: FakeAuthClient())
        userIsLoggedIn = UserIsLoggedInUseCase(userRepository: userRepository)
        observeUserIsLoggedIn = ObserveUserIsLoggedInUseCase(userRepository: userRepository)
        userLogin = UserLoginUseCase(userRepository: userRepository)
        
        // MARK: UI
        bootUIDI = BootUIDI(observeUserIsLoggedInUseCase: observeUserIsLoggedIn)
        
        loginUIDI = LoginUIDI(userLogin: userLogin)
        
        homeUIDI = HomeUIDI(navigation: homeNavigator)
        
        favoritesUIDI = FavoritesUIDI(navigation: favoritesNavigator)
        
        cartUIDI = CartUIDI(navigation: cartNavigator)
                
        mainUIDI = MainUIDI(
            navigator: appNavigator,
            homeUIDI: homeUIDI,
            favoritesUIDI: favoritesUIDI,
            cartUIDI: cartUIDI
        )
    }
}
