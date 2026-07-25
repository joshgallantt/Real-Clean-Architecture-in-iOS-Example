import Foundation
import Session

@MainActor
final class LoginSheetViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let onAuthenticated: () -> Void

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    init(loginUseCase: LoginUseCase, onAuthenticated: @escaping () -> Void) {
        self.loginUseCase = loginUseCase
        self.onAuthenticated = onAuthenticated
    }

    func logIn() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        switch await loginUseCase(email: email, password: password) {
        case .success:
            onAuthenticated()
        case .failure(let failure):
            error = failure.userMessage
        }
    }
}
