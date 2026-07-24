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

    public init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    @MainActor
    public func makeLoginScreenViewModel() -> LoginScreenViewModel {
        LoginScreenViewModel(loginUseCase: loginUseCase)
    }
    
    @MainActor
    public func loginView() -> some View {
        LoginScreenView(viewModel: makeLoginScreenViewModel())
    }

    @MainActor
    public func welcomeView(onContinueAsGuest: @escaping () -> Void) -> some View {
        WelcomeScreenView(
            viewModel: WelcomeScreenViewModel(onContinueAsGuest: onContinueAsGuest),
            loginView: { AnyView(LoginScreenView(viewModel: self.makeLoginScreenViewModel())) }
        )
    }
}
