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
    /// How the end of the flow is paced. The flow owns this, not the sheets: the sheets show
    /// the confirmation, the presenter decides how long it earns and when the screen is free
    /// again.
    private enum Timing {
        /// Long enough to register the greeting, short enough not to stand between the user
        /// and what they were doing when they were asked to log in.
        static let confirmation: Duration = .seconds(1)

        /// The system's sheet dismissal animation. Callers resume only once it has played
        /// out, so what they do next — a snackbar, a navigation — lands on a settled screen
        /// instead of racing the sheet off it.
        static let dismissal: Duration = .milliseconds(350)
    }

    private let sheetPresenting: SheetPresenting
    private let userIsLoggedIn: UserIsLoggedInUseCase
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase
    private let getSession: GetSessionUseCase
    private var waiting: [CheckedContinuation<Bool, Never>] = []
    private var didAuthenticate = false
    private var confirmation: Task<Void, Never>?

    public init(
        sheetPresenting: SheetPresenting,
        userIsLoggedIn: UserIsLoggedInUseCase,
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        getSession: GetSessionUseCase
    ) {
        self.sheetPresenting = sheetPresenting
        self.userIsLoggedIn = userIsLoggedIn
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
        self.getSession = getSession
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
            let getSession = getSession
            presentSheet {
                LoginSheetView(viewModel: LoginSheetViewModel(
                    loginUseCase: loginUseCase,
                    getSession: getSession,
                    onAuthenticated: { [weak self] in self?.authenticationSucceeded() }
                ))
            }
        case .createAccount:
            let createAccountUseCase = createAccountUseCase
            let getSession = getSession
            presentSheet {
                CreateAccountSheetView(viewModel: CreateAccountSheetViewModel(
                    createAccountUseCase: createAccountUseCase,
                    getSession: getSession,
                    onAuthenticated: { [weak self] in self?.authenticationSucceeded() }
                ))
            }
        }
    }

    /// Presenting over a sheet chains to it, so only the user ending the chain is an outcome.
    private func presentSheet<Content: View>(@ViewBuilder _ sheet: () -> Content) {
        sheetPresenting.present(
            onDismiss: { [weak self] in self?.sheetWasDismissedByUser() },
            content: sheet
        )
    }

    /// The sheet is showing its confirmation by now. Leave it up long enough to be read,
    /// take it away, and only then let the waiting callers carry on.
    private func authenticationSucceeded() {
        didAuthenticate = true
        confirmation = Task { [weak self] in
            try? await Task.sleep(for: Timing.confirmation)
            guard let self, !Task.isCancelled else { return }

            self.sheetPresenting.dismiss()

            try? await Task.sleep(for: Timing.dismissal)
            guard !Task.isCancelled else { return }
            self.finish()
        }
    }

    /// SwiftUI reports this once the sheet is already off screen, so there is nothing left
    /// to wait out. Swiping the confirmation away early only skips the rest of its turn —
    /// the user is authenticated either way.
    private func sheetWasDismissedByUser() {
        confirmation?.cancel()
        finish()
    }

    /// Everyone waiting gets the same answer — the flow authenticated the user or it didn't.
    private func finish() {
        confirmation = nil
        let pending = waiting
        let outcome = didAuthenticate
        waiting = []
        didAuthenticate = false
        pending.forEach { $0.resume(returning: outcome) }
    }
}
