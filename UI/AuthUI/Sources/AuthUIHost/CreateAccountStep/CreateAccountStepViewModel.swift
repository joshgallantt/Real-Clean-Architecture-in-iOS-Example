import Foundation
import Session

@MainActor
final class CreateAccountStepViewModel: ObservableObject {
    private let createAccountUseCase: CreateAccountUseCase
    private let getSession: GetSessionUseCase

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published private(set) var confirmation: AuthConfirmation?

    init(createAccountUseCase: CreateAccountUseCase, getSession: GetSessionUseCase) {
        self.createAccountUseCase = createAccountUseCase
        self.getSession = getSession
    }

    /// Last name is the one field the domain accepts empty, so it's the one field the button
    /// doesn't wait for.
    var canSubmit: Bool {
        !isLoading && !firstName.isEmpty && !email.isEmpty && !password.isEmpty
    }

    var hasInput: Bool {
        !firstName.isEmpty || !lastName.isEmpty || !email.isEmpty || !password.isEmpty
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
            confirmation = AuthConfirmation(
                title: "Account Created",
                message: AuthGreeting.welcome(getSession().user?.firstName)
            )
        case .failure(let failure):
            error = failure.userMessage
        }
    }
}
