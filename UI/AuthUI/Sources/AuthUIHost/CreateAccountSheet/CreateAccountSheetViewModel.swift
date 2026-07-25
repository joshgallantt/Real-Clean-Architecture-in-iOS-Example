import Foundation
import Session

@MainActor
final class CreateAccountSheetViewModel: ObservableObject {
    private let createAccountUseCase: CreateAccountUseCase
    private let onAuthenticated: () -> Void

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    init(createAccountUseCase: CreateAccountUseCase, onAuthenticated: @escaping () -> Void) {
        self.createAccountUseCase = createAccountUseCase
        self.onAuthenticated = onAuthenticated
    }

    func createAccount() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        let result = await createAccountUseCase(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
        switch result {
        case .success:
            onAuthenticated()
        case .failure(let failure):
            error = failure.userMessage
        }
    }
}
