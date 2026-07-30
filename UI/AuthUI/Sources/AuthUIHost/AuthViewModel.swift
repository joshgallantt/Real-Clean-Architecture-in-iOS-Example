import Foundation
import SwiftUI
import Session
import AuthUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var mode: AuthMode
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published private(set) var confirmationMessage: String?

    private let openedMode: AuthMode
    private let prompt: AuthenticationPrompt?
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase
    private let getSession: GetSessionUseCase
    private let onAuthenticated: () -> Void

    init(
        mode: AuthMode,
        prompt: AuthenticationPrompt?,
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        getSession: GetSessionUseCase,
        onAuthenticated: @escaping () -> Void
    ) {
        self.mode = mode
        self.openedMode = mode
        self.prompt = prompt
        self.loginUseCase = loginUseCase
        self.createAccountUseCase = createAccountUseCase
        self.getSession = getSession
        self.onAuthenticated = onAuthenticated
    }

    /// Only the mode the flow opened on wears the prompt: it is the reason the sheet is
    /// here, and it stops being the reason once the user has chosen to go elsewhere in it.
    var icon: String {
        mode == openedMode ? (prompt?.icon ?? mode.icon) : mode.icon
    }

    var title: String {
        mode == openedMode ? (prompt?.title ?? mode.title) : mode.title
    }

    var subtitle: String {
        mode == openedMode ? (prompt?.message ?? mode.subtitle) : mode.subtitle
    }

    var confirmationTitle: String { mode.confirmationTitle }

    var canSubmit: Bool {
        guard !isLoading else { return false }
        switch mode {
        case .logIn:
            return !email.isEmpty && !password.isEmpty
        case .createAccount:
            return !firstName.isEmpty && !email.isEmpty && !password.isEmpty
        }
    }

    var hasUnsavedInput: Bool {
        confirmationMessage == nil &&
            (!firstName.isEmpty || !lastName.isEmpty || !email.isEmpty || !password.isEmpty)
    }

    func switchToPeerMode() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            mode = mode.peer
            error = nil
        }
    }

    func submit() async {
        guard canSubmit else { return }
        error = nil
        isLoading = true
        defer { isLoading = false }

        switch mode {
        case .logIn:
            switch await loginUseCase(email: Email(email), password: Password(password)) {
            case .success:
                confirmationMessage = greeting("Welcome back")
                onAuthenticated()
            case .failure(let failure):
                error = failure.userMessage
            }
        case .createAccount:
            let result = await createAccountUseCase(
                name: PersonName(first: firstName, last: lastName),
                email: Email(email),
                password: Password(password)
            )
            switch result {
            case .success:
                confirmationMessage = greeting("Welcome")
                onAuthenticated()
            case .failure(let failure):
                error = failure.userMessage
            }
        }
    }

    private func greeting(_ lead: String) -> String {
        guard let name = getSession().user?.name.first, !name.isEmpty else {
            return "\(lead)."
        }
        return "\(lead), \(name)."
    }
}
