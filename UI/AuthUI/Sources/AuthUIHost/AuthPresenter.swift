import SwiftUI
import Session
import SheetUI
import AuthUI

/// Default `AuthPresenting` implementation: runs the flow as a chain of sheets and resolves
/// everyone waiting on it once the user completes it or dismisses it. Built on the generic
/// `SheetPresenting` primitive, so it knows nothing about *how* sheets get presented — only
/// what this flow is.
@MainActor
public final class AuthPresenter: AuthPresenting {
    private let sheetPresenting: SheetPresenting
    private let userIsLoggedIn: UserIsLoggedInUseCase
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase
    private var waiting: [CheckedContinuation<Bool, Never>] = []

    public init(
        sheetPresenting: SheetPresenting,
        userIsLoggedIn: UserIsLoggedInUseCase,
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase
    ) {
        self.sheetPresenting = sheetPresenting
        self.userIsLoggedIn = userIsLoggedIn
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
    }

    @discardableResult
    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        await authenticate(startingAt: .chooser(prompt))
    }

    /// Skips the chooser, for a caller that already knows which one the user wants — a
    /// dedicated "Log In" button.
    @discardableResult
    func logIn() async -> Bool {
        await authenticate(startingAt: .logIn)
    }

    /// Skips the chooser. See `logIn()`.
    @discardableResult
    func createAccount() async -> Bool {
        await authenticate(startingAt: .createAccount)
    }

    private func authenticate(startingAt step: AuthenticationStep) async -> Bool {
        if await userIsLoggedIn() {
            return true
        }
        return await withCheckedContinuation { continuation in
            waiting.append(continuation)
            present(step)
        }
    }

    private func present(_ step: AuthenticationStep) {
        switch step {
        case .chooser(let prompt):
            presentSheet {
                AuthenticationChooserSheetView(
                    prompt: prompt,
                    onSelectLogIn: { [weak self] in self?.present(.logIn) },
                    onSelectCreateAccount: { [weak self] in self?.present(.createAccount) }
                )
            }
        case .logIn:
            let loginUseCase = loginUseCase
            presentSheet {
                LoginSheetView(viewModel: LoginSheetViewModel(
                    loginUseCase: loginUseCase,
                    onAuthenticated: { [weak self] in self?.authenticationSucceeded() }
                ))
            }
        case .createAccount:
            let createAccountUseCase = createAccountUseCase
            presentSheet {
                CreateAccountSheetView(viewModel: CreateAccountSheetViewModel(
                    createAccountUseCase: createAccountUseCase,
                    onAuthenticated: { [weak self] in self?.authenticationSucceeded() }
                ))
            }
        }
    }

    /// Presenting over a sheet chains to it, so only the user ending the chain is an outcome.
    private func presentSheet<Content: View>(@ViewBuilder _ sheet: () -> Content) {
        sheetPresenting.present(
            onDismiss: { [weak self] in self?.resolveAll(with: false) },
            content: sheet
        )
    }

    private func authenticationSucceeded() {
        sheetPresenting.dismiss()
        resolveAll(with: true)
    }

    /// Everyone waiting gets the same answer — the flow authenticated the user or it didn't.
    private func resolveAll(with isAuthenticated: Bool) {
        let pending = waiting
        waiting = []
        pending.forEach { $0.resume(returning: isAuthenticated) }
    }
}
