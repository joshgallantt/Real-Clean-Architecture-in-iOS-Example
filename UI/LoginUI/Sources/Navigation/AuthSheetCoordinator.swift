import SwiftUI
import Session
import SheetUI

/// Single responsibility: run the "authenticate, then resume" flow — chaining a gate to
/// Log In / Create Account and resolving every caller waiting on `requireAuthentication`
/// once it completes or is dismissed. Built on the generic `SheetPresenting` primitive, so
/// it knows nothing about *how* sheets get presented, only what this specific flow is.
@MainActor
public final class AuthSheetCoordinator {
    private var continuations: [CheckedContinuation<Bool, Never>] = []
    private let sheetPresenting: SheetPresenting
    private let requireAuthenticationUseCase: RequireAuthenticationUseCase
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase

    public init(
        sheetPresenting: SheetPresenting,
        requireAuthenticationUseCase: RequireAuthenticationUseCase,
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase
    ) {
        self.sheetPresenting = sheetPresenting
        self.requireAuthenticationUseCase = requireAuthenticationUseCase
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
    }

    /// Presents the default Log In / Create Account chooser.
    @discardableResult
    public func requireAuthentication() async -> Bool {
        await requireAuthentication { onSelectLogIn, onSelectCreateAccount in
            AnyView(LoginOrCreateAccountSheetView(
                message: "Sign in to continue",
                onSelectLogIn: onSelectLogIn,
                onSelectCreateAccount: onSelectCreateAccount
            ))
        }
    }

    /// Presents a custom gate in place of the default chooser. `gate` receives
    /// `onSelectLogIn`/`onSelectCreateAccount` callbacks to wire into its own UI — use this
    /// when a feature wants a bespoke "why sign in" sheet instead of the generic message.
    ///
    /// - Returns: `true` if the user is authenticated (already was, or just completed the
    ///   auth flow), `false` if they dismissed it without authenticating.
    @discardableResult
    public func requireAuthentication(
        gate: @escaping (_ onSelectLogIn: @escaping () -> Void, _ onSelectCreateAccount: @escaping () -> Void) -> AnyView
    ) async -> Bool {
        if await requireAuthenticationUseCase() {
            return true
        }
        return await withCheckedContinuation { continuation in
            continuations.append(continuation)
            presentGate(gate)
        }
    }

    private func presentGate(_ gate: @escaping (@escaping () -> Void, @escaping () -> Void) -> AnyView) {
        sheetPresenting.present(onDismiss: { [weak self] in self?.resolve(false) }) {
            gate(
                { [weak self] in self?.presentLogin() },
                { [weak self] in self?.presentCreateAccount() }
            )
        }
    }

    private func presentLogin() {
        sheetPresenting.present(onDismiss: { [weak self] in self?.resolve(false) }) { [self] in
            LoginSheetView(
                viewModel: LoginSheetViewModel(loginUseCase: self.loginUseCase, onAuthenticated: { [weak self] in
                    self?.completeAndDismiss()
                })
            )
        }
    }

    private func presentCreateAccount() {
        sheetPresenting.present(onDismiss: { [weak self] in self?.resolve(false) }) { [self] in
            CreateAccountSheetView(
                viewModel: CreateAccountSheetViewModel(createAccountUseCase: self.createAccountUseCase, onAuthenticated: { [weak self] in
                    self?.completeAndDismiss()
                })
            )
        }
    }

    private func completeAndDismiss() {
        sheetPresenting.dismissCurrentSheet()
        resolve(true)
    }

    private func resolve(_ success: Bool) {
        let pending = continuations
        continuations = []
        pending.forEach { $0.resume(returning: success) }
    }
}
