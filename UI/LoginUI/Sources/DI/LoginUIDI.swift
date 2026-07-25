//
//  LoginUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import LoginUI
import Session

public struct LoginUIDI {
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase

    public init(
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
    }

    @MainActor
    public func loginView(onAuthenticated: @escaping () -> Void) -> some View {
        NavigationStack {
            LoginScreenView(
                viewModel: LoginScreenViewModel(loginUseCase: loginUseCase, onAuthenticated: onAuthenticated)
            )
        }
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
        NavigationStack {
            CreateAccountScreenView(
                viewModel: CreateAccountScreenViewModel(createAccountUseCase: createAccountUseCase, onAuthenticated: onAuthenticated)
            )
        }
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
