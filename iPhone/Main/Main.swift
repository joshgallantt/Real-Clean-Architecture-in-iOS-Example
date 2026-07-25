//
//  Main.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import SwiftUI
import LoginUIDI
import OnboardingUIDI

private enum AuthSheet: String, Identifiable {
    case chooser
    case logIn
    case createAccount

    var id: String { rawValue }
}

@main
struct Main: App {
    @StateObject private var viewModel = Injector.shared.makeMainViewModel()
    @StateObject private var authPresenter = Injector.shared.authPresenter
    @State private var authSheet: AuthSheet?

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
                    .onChange(of: authPresenter.isPresentingAuth) { _, isPresenting in
                        authSheet = isPresenting ? .chooser : nil
                    }
                    .sheet(item: $authSheet, onDismiss: {
                        if authSheet == nil {
                            authPresenter.isPresentingAuth = false
                            authPresenter.cancelAuthentication()
                        }
                    }) { sheet in
                        switch sheet {
                        case .chooser:
                            Injector.shared.loginUIDI.loginOrCreateAccountView(
                                message: "Wishlist Requires an Account",
                                onSelectLogIn: { authSheet = .logIn },
                                onSelectCreateAccount: { authSheet = .createAccount }
                            )
                        case .logIn:
                            Injector.shared.loginUIDI.loginView(
                                onAuthenticated: {
                                    authSheet = nil
                                    authPresenter.completeAuthentication()
                                }
                            )
                        case .createAccount:
                            Injector.shared.loginUIDI.createAccountView(
                                onAuthenticated: {
                                    authSheet = nil
                                    authPresenter.completeAuthentication()
                                }
                            )
                        }
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
