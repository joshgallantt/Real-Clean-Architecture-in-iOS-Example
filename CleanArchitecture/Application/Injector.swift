//
//  Injector.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import HomeUIDI
import WishlistUIDI
import CartUIDI
import LoginUIDI
import UserDI
import UserData

final class Injector {
    static let shared = Injector()
    
    // MARK: - Components
    private let userDI: UserDI

    // MARK: - Feature Navigators
    let appNavigator: AppNavigator
    private let homeNavigator: HomeNavigator
    private let wishlistNavigator: WishlistNavigator
    private let cartNavigator: CartNavigator
    
    // MARK: - UIDI Properties
    let bootUIDI: BootUIDI
    let loginUIDI: LoginUIDI
    let mainUIDI: MainUIDI
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    private init() {
        // MARK: Navigation
        appNavigator = AppNavigator()
        homeNavigator = HomeNavigator(navigator: appNavigator)
        cartNavigator = CartNavigator(navigator: appNavigator)
        wishlistNavigator = WishlistNavigator(navigator: appNavigator)
        
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
        wishlistUIDI = WishlistUIDI(
            navigation: wishlistNavigator
        )
        cartUIDI = CartUIDI(
            navigation: cartNavigator
        )
        mainUIDI = MainUIDI(
            navigator: appNavigator,
            homeUIDI: homeUIDI,
            wishlistUIDI: wishlistUIDI,
            cartUIDI: cartUIDI
        )
    }
    
}
