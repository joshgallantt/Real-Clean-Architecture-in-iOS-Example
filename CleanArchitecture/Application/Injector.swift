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
    private let userSession: UserSession
    private let userRepository: UserRepository
    private let userIsLoggedIn: UserIsLoggedInUseCase
    private let observeUserIsLoggedIn: ObserveUserIsLoggedInUseCase
    private let userLogin: UserLoginUseCase

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
        
        // MARK: Domain Component - User
        userSession = UserSession()
        userRepository = DefaultUserRepository(session: userSession, authClient: FakeAuthClient())
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
