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

    // MARK: - Feature Navigation
    let appNavigator: Navigator
    private let homeNavigation: DefaultHomeNavigation
    private let wishlistNavigation: DefaultWishlistNavigation
    private let cartNavigation: DefaultCartNavigation
    
    // MARK: - UIDI Properties
    let rootUIDI: RootUIDI
    let loginUIDI: LoginUIDI
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    private init() {
        // MARK: Navigation
        appNavigator = Navigator()
        homeNavigation = DefaultHomeNavigation(navigator: appNavigator)
        cartNavigation = DefaultCartNavigation(navigator: appNavigator)
        wishlistNavigation = DefaultWishlistNavigation(navigator: appNavigator)
        
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
            navigation: homeNavigation
        )
        wishlistUIDI = WishlistUIDI(
            navigation: wishlistNavigation
        )
        cartUIDI = CartUIDI(
            navigation: cartNavigation
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
