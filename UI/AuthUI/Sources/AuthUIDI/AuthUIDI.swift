//
//  AuthUIDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI
import AuthUI
import Session
import SheetUI

public struct AuthUIDI {
    /// One shared presenter for the whole app — inject this wherever a feature needs to hold
    /// an action back until the user is authenticated.
    public let presenter: AuthPresenter

    @MainActor
    public init(
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        getSessionUseCase: GetSessionUseCase,
        sheetPresenting: SheetPresenting
    ) {
        self.presenter = AuthPresenter(
            sheetPresenting: sheetPresenting,
            loginUseCase: loginUseCase,
            createAccountUseCase: createAccountUseCase,
            getSession: getSessionUseCase
        )
    }

    /// A self-contained "Log In" button: tapping it presents the Log In sheet directly and
    /// resolves on its own. Most callers need no completion closure — the screen just reacts
    /// to the resulting session change. `onAuthenticated` is for the ones that can't, because
    /// what they do next has to wait for the sheet to be gone; it fires once it is.
    @MainActor
    public func loginButtonView(
        title: String = "Log In",
        onAuthenticated: @escaping () -> Void = {}
    ) -> some View {
        Button {
            Task {
                if await presenter.logIn() { onAuthenticated() }
            }
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
    }

    /// A self-contained "Create Account" button — see `loginButtonView(title:onAuthenticated:)`.
    @MainActor
    public func createAccountButtonView(
        title: String = "Create Account",
        onAuthenticated: @escaping () -> Void = {}
    ) -> some View {
        Button {
            Task {
                if await presenter.createAccount() { onAuthenticated() }
            }
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
    }

    /// - Parameter onAuthenticated: fires once the flow's sheet has left the screen, not the
    ///   moment the session changes — this screen is underneath that sheet, so replacing it
    ///   any earlier pulls the ground out from under the confirmation the user is reading.
    @MainActor
    public func welcomeView(
        onContinueAsGuest: @escaping () -> Void,
        onAuthenticated: @escaping () -> Void
    ) -> some View {
        WelcomeScreenView(
            viewModel: WelcomeScreenViewModel(
                presenter: presenter,
                onContinueAsGuest: onContinueAsGuest,
                onAuthenticated: onAuthenticated
            )
        )
    }
}
