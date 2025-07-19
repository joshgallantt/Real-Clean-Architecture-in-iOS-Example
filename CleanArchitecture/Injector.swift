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
    let appNavigator: Navigation
    private let homeNavigator: HomeNavigator
    private let wishlistNavigator: WishlistNavigator
    private let cartNavigator: CartNavigator
    
    // MARK: - UIDI Properties
    let rootUIDI: RootUIDI
    let loginUIDI: LoginUIDI
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    private init() {
        // MARK: Navigation
        appNavigator = Navigation()
        homeNavigator = HomeNavigator(navigator: appNavigator)
        cartNavigator = CartNavigator(navigator: appNavigator)
        wishlistNavigator = WishlistNavigator(navigator: appNavigator)
        
        // MARK: User Component DI
        let userRepository = DefaultUserRepository(
            session: UserSession(),
            authClient: FakeAuthClient()
        )
        userDI = UserDI(userRepository: userRepository)

        // MARK: UI Features
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
        rootUIDI = RootUIDI(
            observeUserIsLoggedInUseCase: userDI.observeUserIsLoggedInUseCase,
            loginUIDI: loginUIDI,
            homeUIDI: homeUIDI,
            wishlistUIDI: wishlistUIDI,
            cartUIDI: cartUIDI,
            navigator: appNavigator
        )
    }
}
