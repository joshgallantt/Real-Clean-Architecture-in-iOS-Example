import Foundation
import Session

@MainActor
public final class CreateAccountScreenViewModel: ObservableObject {
    private let createAccountUseCase: CreateAccountUseCase
    private let onAuthenticated: () -> Void

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    public init(createAccountUseCase: CreateAccountUseCase, onAuthenticated: @escaping () -> Void) {
        self.createAccountUseCase = createAccountUseCase
        self.onAuthenticated = onAuthenticated
    }

    func createAccount() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        let result = await createAccountUseCase(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
        switch result {
        case .success:
            onAuthenticated()
        case .failure(let createAccountError):
            self.error = message(for: createAccountError)
        }
    }

    private func message(for error: CreateAccountError) -> String {
        switch error {
        case .firstNameIsEmpty:
            return "First name is required."
        case .emailIsEmpty:
            return "Email is required."
        case .passwordIsEmpty:
            return "Password is required."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
