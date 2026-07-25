import Foundation
import Session

@MainActor
final class LoginSheetViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let getSession: GetSessionUseCase
    private let onAuthenticated: () -> Void

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published private(set) var successGreeting: String?

    init(
        loginUseCase: LoginUseCase,
        getSession: GetSessionUseCase,
        onAuthenticated: @escaping () -> Void
    ) {
        self.loginUseCase = loginUseCase
        self.getSession = getSession
        self.onAuthenticated = onAuthenticated
    }

    func logIn() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        switch await loginUseCase(email: email, password: password) {
        case .success:
            successGreeting = AuthGreeting.welcomeBack(getSession().user?.firstName)
            onAuthenticated()
        case .failure(let failure):
            error = failure.userMessage
        }
    }
}
