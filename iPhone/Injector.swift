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

@MainActor
final class Injector {
    static let shared = Injector()
    
    // MARK: - Components
    let userDI: UserDI

    // MARK: - Feature Navigation
    let navigator: Navigator
    
    // MARK: - UIDI Properties
    let loginUIDI: LoginUIDI
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    private init() {
        // MARK: Navigation
        navigator = Navigator()
        
        // MARK: User Component DI
        userDI = UserDI()

        // MARK: UI Features
        loginUIDI = LoginUIDI(userDI: userDI)
        homeUIDI = HomeUIDI(navigation: navigator)
        wishlistUIDI = WishlistUIDI(navigation: navigator)
        cartUIDI = CartUIDI(navigation: navigator)
    }
}
