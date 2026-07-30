import SwiftUI
import AuthUI
import Session
import SheetUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct AuthUIDI {
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
