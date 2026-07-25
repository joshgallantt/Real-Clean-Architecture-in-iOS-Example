//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import LoginUI
import Session
import SheetUI

public struct LoginUIDI {
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase

    /// One shared instance for the whole app — attach `.sheetHost(_:)` wherever makes
    /// sense to present from (it doesn't have to be the app root).
    public let sheetCoordinator: SheetCoordinator

    /// One shared instance for the whole app — inject this wherever a feature needs to
    /// gate an action on authentication.
    public let authSheetCoordinator: AuthSheetCoordinator

    @MainActor
    public init(
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        requireAuthenticationUseCase: RequireAuthenticationUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
        let sheetCoordinator = SheetCoordinator()
        self.sheetCoordinator = sheetCoordinator
        self.authSheetCoordinator = AuthSheetCoordinator(
            sheetPresenting: sheetCoordinator,
            requireAuthenticationUseCase: requireAuthenticationUseCase,
            loginUseCase: loginUseCase,
            createAccountUseCase: createAccountUseCase
        )
    }

    @MainActor
    public func loginView(onAuthenticated: @escaping () -> Void) -> some View {
        LoginSheetView(
            viewModel: LoginSheetViewModel(loginUseCase: loginUseCase, onAuthenticated: onAuthenticated)
        )
    }

    @MainActor
    public func loginOrCreateAccountView(
        message: String,
        onSelectLogIn: @escaping () -> Void,
        onSelectCreateAccount: @escaping () -> Void
    ) -> some View {
        LoginOrCreateAccountSheetView(
            message: message,
            onSelectLogIn: onSelectLogIn,
            onSelectCreateAccount: onSelectCreateAccount
        )
    }

    @MainActor
    public func createAccountView(onAuthenticated: @escaping () -> Void) -> some View {
        CreateAccountSheetView(
            viewModel: CreateAccountSheetViewModel(createAccountUseCase: createAccountUseCase, onAuthenticated: onAuthenticated)
        )
    }

    @MainActor
    public func welcomeView(onContinueAsGuest: @escaping () -> Void) -> some View {
        WelcomeScreenView(
            viewModel: WelcomeScreenViewModel(onContinueAsGuest: onContinueAsGuest),
            loginView: { onAuthenticated in AnyView(self.loginView(onAuthenticated: onAuthenticated)) },
            createAccountView: { onAuthenticated in AnyView(self.createAccountView(onAuthenticated: onAuthenticated)) }
        )
    }
}
