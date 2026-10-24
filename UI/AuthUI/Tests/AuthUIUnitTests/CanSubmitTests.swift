import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
@testable import AuthUIDI

@MainActor
@Suite("Whether the form can be submitted")
struct CanSubmitTests {
    private func makeViewModel(
        mode: AuthMode = .logIn,
        loginUseCase: SpyLoginUseCase = SpyLoginUseCase(),
        createAccountUseCase: SpyCreateAccountUseCase = SpyCreateAccountUseCase(),
        getSession: StubGetSessionUseCase = StubGetSessionUseCase()
    ) -> AuthViewModel {
        AuthViewModel(
            mode: mode,
            prompt: nil,
            loginUseCase: loginUseCase,
            createAccountUseCase: createAccountUseCase,
            getSession: getSession,
            onAuthenticated: {}
        )
    }

    @Test("Logging in needs an email and a password, nothing more")
    func logInNeedsAnEmailAndAPassword() {
        let viewModel = makeViewModel(mode: .logIn)
        #expect(viewModel.canSubmit == false)

        viewModel.email = "ada@example.com"
        #expect(viewModel.canSubmit == false)

        viewModel.password = "hunter2"
        #expect(viewModel.canSubmit)
    }

    @Test("Creating an account also needs a first name")
    func creatingAnAccountAlsoNeedsAFirstName() {
        let viewModel = makeViewModel(mode: .createAccount)
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"
        #expect(viewModel.canSubmit == false)

        viewModel.firstName = "Ada"
        #expect(viewModel.canSubmit)
    }

    @Test("Nothing can be submitted while the last submission is still in flight")
    func nothingIsSubmittedWhileTheLastOneIsInFlight() async {
        let loginUseCase = SpyLoginUseCase()
        loginUseCase.result = .failure(.unavailable)
        let viewModel = makeViewModel(mode: .logIn, loginUseCase: loginUseCase)
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"

        #expect(viewModel.canSubmit)
        await viewModel.submit()
        #expect(viewModel.canSubmit)
    }
}
