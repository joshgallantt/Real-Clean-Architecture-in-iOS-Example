import SwiftUI
import Session
import SheetUI
import AuthUI

@MainActor
public final class AuthPresenter: AuthPresenting {
    private enum Timing {
        static let confirmation: Duration = .seconds(1)

        static let dismissal: Duration = .milliseconds(350)
    }

    private let sheetPresenting: SheetPresenting
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase
    private let getSession: GetSessionUseCase
    private var waiting: [CheckedContinuation<Bool, Never>] = []
    private var didAuthenticate = false
    private var confirmationTask: Task<Void, Never>?

    public init(
        sheetPresenting: SheetPresenting,
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        getSession: GetSessionUseCase
    ) {
        self.sheetPresenting = sheetPresenting
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
        self.getSession = getSession
    }

    @discardableResult
    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        await authenticate(mode: .logIn, prompt: prompt)
    }

    @discardableResult
    func logIn() async -> Bool {
        await authenticate(mode: .logIn, prompt: nil)
    }

    @discardableResult
    func createAccount() async -> Bool {
        await authenticate(mode: .createAccount, prompt: nil)
    }

    private func authenticate(mode: AuthMode, prompt: AuthenticationPrompt?) async -> Bool {
        if getSession().isLoggedIn {
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

    private func sheetWasDismissedByUser() {
        confirmationTask?.cancel()
        finish()
    }

    private func finish() {
        confirmationTask = nil
        let pending = waiting
        let outcome = didAuthenticate
        waiting = []
        didAuthenticate = false
        pending.forEach { $0.resume(returning: outcome) }
    }
}
