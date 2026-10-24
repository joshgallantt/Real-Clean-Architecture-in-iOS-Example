import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
@testable import AuthUIDI

@MainActor
@Suite("Creating an account")
struct CreatingAnAccountTests {
    private func makeViewModel(
        createAccountUseCase: SpyCreateAccountUseCase,
        onAuthenticated: @escaping () -> Void = {}
    ) -> AuthViewModel {
        let viewModel = AuthViewModel(
            mode: .createAccount,
            prompt: nil,
            loginUseCase: SpyLoginUseCase(),
            createAccountUseCase: createAccountUseCase,
            getSession: StubGetSessionUseCase(),
            onAuthenticated: onAuthenticated
        )
        viewModel.firstName = "Ada"
        viewModel.lastName = "Lovelace"
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"
        return viewModel
    }

    @Test("What was typed is handed to the use case as a name, an email and a password")
    func passesWhatWasTyped() async {
        let createAccountUseCase = SpyCreateAccountUseCase()
        let viewModel = makeViewModel(createAccountUseCase: createAccountUseCase)

        await viewModel.submit()

        #expect(createAccountUseCase.calls.map(\.name) == [PersonName(first: "Ada", last: "Lovelace")])
        #expect(createAccountUseCase.calls.map(\.email) == [Email("ada@example.com")])
    }

    @Test("An email already in use says so, and nobody is told the shopper signed in")
    func anEmailAlreadyInUseSaysSo() async {
        let createAccountUseCase = SpyCreateAccountUseCase()
        createAccountUseCase.result = .failure(.emailAlreadyInUse)
        var authenticated = false
        let viewModel = makeViewModel(createAccountUseCase: createAccountUseCase, onAuthenticated: { authenticated = true })

        await viewModel.submit()

        #expect(authenticated == false)
        #expect(viewModel.error == "An account with this email already exists.")
    }
}
