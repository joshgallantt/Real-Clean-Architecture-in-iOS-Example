//
//  Main.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import AuthUIDI
import OnboardingUIDI
import SheetUIDI
import SnackbarUIDI

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
                    Injector.shared.authUIDI.welcomeView(
                        onContinueAsGuest: { viewModel.continueAsGuest() },
                        onAuthenticated: { viewModel.authenticationFinished() }
                    )
                case .onboarding:
                    Injector.shared.onboardingUIDI.onboardingView(
                        onFinish: { viewModel.continueAsGuest() }
                    )
                case .main:
                    TabScreen(
                        navigator: Injector.shared.navigator,
                        snackbarPresenter: Injector.shared.snackbarUIDI.presenter,
                        homeView: Injector.shared.homeView,
                        searchView: Injector.shared.searchView,
                        wishlistView: Injector.shared.wishlistView,
                        bagView: Injector.shared.bagView,
                        accountView: Injector.shared.accountView
                    )
                }
            }
            .animation(.easeInOut, value: viewModel.phase)
            // Hosted above the phase switch, not inside a branch: the authentication flow is
            // reachable from Welcome as well as from the tabs, and a sheet that is up when
            // the phase changes should outlive the screen that opened it.
            .sheetHost(Injector.shared.sheetUIDI.presenter)
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
