//
//  Main.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import SwiftUI
import LoginUIDI
import OnboardingUIDI

@main
struct Main: App {
    @StateObject private var viewModel = Injector.shared.makeMainViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch viewModel.phase {
                case .splash:
                    SplashView()
                case .welcome:
                    Injector.shared.loginUIDI.welcomeView(
                        onContinueAsGuest: { viewModel.continueAsGuest() }
                    )
                case .onboarding:
                    Injector.shared.onboardingUIDI.onboardingView(
                        onFinish: { viewModel.continueAsGuest() }
                    )
                case .main:
                    TabScreen(
                        navigator: Injector.shared.navigator,
                        homeView: Injector.shared.homeView,
                        searchView: Injector.shared.searchView,
                        wishlistView: Injector.shared.wishlistView,
                        bagView: Injector.shared.bagView,
                        accountView: Injector.shared.accountView,
                        loginView: Injector.shared.loginView
                    )
                }
            }
            .animation(.easeInOut, value: viewModel.phase)
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
