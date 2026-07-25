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
    @StateObject private var authGate = Injector.shared.authGate

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
                        snackbarPresenter: Injector.shared.snackbarPresenter,
                        homeView: Injector.shared.homeView,
                        searchView: Injector.shared.searchView,
                        wishlistView: Injector.shared.wishlistView,
                        bagView: Injector.shared.bagView,
                        accountView: Injector.shared.accountView
                    )
                    .sheet(isPresented: $authGate.isPresentingAuth, onDismiss: {
                        authGate.cancelAuthentication()
                    }) {
                        Injector.shared.loginUIDI.loginView(
                            onAuthenticated: { authGate.completeAuthentication() }
                        )
                    }
                }
            }
            .animation(.easeInOut, value: viewModel.phase)
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
