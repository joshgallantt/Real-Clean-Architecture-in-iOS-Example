//
//  Main.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import SwiftUI
import Foundation
import Combine
import UserDI
import LoginUIDI

@main
struct Main: App {
    @StateObject private var viewModel = MainViewModel(
        observeUserLoggedIn: Injector.shared.userDI.observeUserIsLoggedInUseCase
    )
    
    init() {
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch viewModel.path {
                case .login:
                    Injector.shared.loginUIDI.loginView()
                case .main:
                    TabScreen(
                        navigator: Injector.shared.navigator,
                        homeView: Injector.shared.homeView,
                        wishlistView: Injector.shared.wishlistView,
                        cartView: Injector.shared.cartView
                    )
                }
            }
        }
    }
}
