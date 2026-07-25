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
    public func makeLoginScreenViewModel() -> LoginScreenViewModel {
        LoginScreenViewModel(loginUseCase: loginUseCase)
    }

    @MainActor
    public func makeCreateAccountScreenViewModel() -> CreateAccountScreenViewModel {
        CreateAccountScreenViewModel(createAccountUseCase: createAccountUseCase)
    }

    @MainActor
    public func createAccountView() -> some View {
        CreateAccountScreenView(viewModel: makeCreateAccountScreenViewModel())
    }

    @MainActor
    public func loginView() -> some View {
        NavigationStack {
            LoginScreenView(
                viewModel: makeLoginScreenViewModel(),
                createAccountView: { AnyView(self.createAccountView()) }
            )
        }
    }

    @MainActor
    public func welcomeView(onContinueAsGuest: @escaping () -> Void) -> some View {
        WelcomeScreenView(
            viewModel: WelcomeScreenViewModel(onContinueAsGuest: onContinueAsGuest),
            loginView: { AnyView(self.loginView()) },
            createAccountView: { AnyView(NavigationStack { self.createAccountView() }) }
        )
    }
}
