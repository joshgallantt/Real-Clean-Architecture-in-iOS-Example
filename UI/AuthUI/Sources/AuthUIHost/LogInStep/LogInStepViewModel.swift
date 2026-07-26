import Foundation
import Session

@MainActor
final class LogInStepViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let getSession: GetSessionUseCase

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published private(set) var confirmation: AuthConfirmation?

    init(loginUseCase: LoginUseCase, getSession: GetSessionUseCase) {
        self.loginUseCase = loginUseCase
        self.getSession = getSession
    }

    /// The domain rejects empty fields anyway. A button that holds itself back says so
    /// before the user has to find out.
    var canSubmit: Bool {
        !isLoading && !email.isEmpty && !password.isEmpty
    }

    var hasInput: Bool {
        !email.isEmpty || !password.isEmpty
    }

    func logIn() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        switch await loginUseCase(email: email, password: password) {
        case .success:
            confirmation = AuthConfirmation(
                title: "Login Successful",
                message: AuthGreeting.welcomeBack(getSession().user?.firstName)
            )
        case .failure(let failure):
            error = failure.userMessage
        }
    }
}
