import SwiftUI
import Session
import SheetUI
import AuthUI

/// Default `AuthPresenting` implementation: runs the flow as a single sheet and resolves
/// everyone waiting on it once the user completes it or dismisses it. Built on the generic
/// `SheetPresenting` primitive, so it knows nothing about *how* sheets get presented — only
/// what this flow is.
@MainActor
public final class AuthPresenter: AuthPresenting {
    /// How the end of the flow is paced. The flow owns this, not the sheet: the sheet shows
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
    private var confirmationTask: Task<Void, Never>?

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

    /// Opens on Log In, because that's the shorter road for the people most likely to be on
    /// it, and creating an account is one tap from there.
    @discardableResult
    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        await authenticate(mode: .logIn, prompt: prompt)
    }

    /// For a caller that already knows which form the user wants — a dedicated "Log In"
    /// button. No prompt: the button they just pressed is the explanation.
    @discardableResult
    func logIn() async -> Bool {
        await authenticate(mode: .logIn, prompt: nil)
    }

    /// See `logIn()`.
    @discardableResult
    func createAccount() async -> Bool {
        await authenticate(mode: .createAccount, prompt: nil)
    }

    private func authenticate(mode: AuthMode, prompt: AuthenticationPrompt?) async -> Bool {
        if await userIsLoggedIn() {
            return true
        }
        if !waiting.isEmpty {
            return await withCheckedContinuation { waiting.append($0) }
        }
        return await withCheckedContinuation { continuation in
            waiting.append(continuation)
            present(mode: mode, prompt: prompt)
        }
    }

    private func present(mode: AuthMode, prompt: AuthenticationPrompt?) {
        let loginUseCase = loginUseCase
        let createAccountUseCase = createAccountUseCase
        let getSession = getSession

        sheetPresenting.present(
            onDismiss: { [weak self] in self?.sheetWasDismissedByUser() },
            content: {
                AuthSheetView(viewModel: AuthViewModel(
                    mode: mode,
                    prompt: prompt,
                    loginUseCase: loginUseCase,
                    createAccountUseCase: createAccountUseCase,
                    getSession: getSession,
                    onAuthenticated: { [weak self] in self?.authenticationSucceeded() }
                ))
            }
        )
    }

    /// The sheet is showing its confirmation by now. Leave it up long enough to be read,
    /// take it away, and only then let the waiting callers carry on.
    private func authenticationSucceeded() {
        didAuthenticate = true
        confirmationTask = Task { [weak self] in
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
        confirmationTask?.cancel()
        finish()
    }

    /// Everyone waiting gets the same answer — the flow authenticated the user or it didn't.
    private func finish() {
        confirmationTask = nil
        let pending = waiting
        let outcome = didAuthenticate
        waiting = []
        didAuthenticate = false
        pending.forEach { $0.resume(returning: outcome) }
    }
}
