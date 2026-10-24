import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
@testable import AuthUIDI

@MainActor
@Suite("Logging in")
struct LoggingInTests {
    private func makeViewModel(
        loginUseCase: SpyLoginUseCase,
        getSession: StubGetSessionUseCase = StubGetSessionUseCase(),
        onAuthenticated: @escaping () -> Void = {}
    ) -> AuthViewModel {
        let viewModel = AuthViewModel(
            mode: .logIn,
            prompt: nil,
            loginUseCase: loginUseCase,
            createAccountUseCase: SpyCreateAccountUseCase(),
            getSession: getSession,
            onAuthenticated: onAuthenticated
        )
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"
        return viewModel
    }

    @Test("A correct email and password are handed straight to the use case")
    func passesEmailAndPassword() async {
        let loginUseCase = SpyLoginUseCase()
        let viewModel = makeViewModel(loginUseCase: loginUseCase)

        await viewModel.submit()

        #expect(loginUseCase.calls.map(\.email) == [Email("ada@example.com")])
        #expect(loginUseCase.calls.map(\.password) == [Password("hunter2")])
    }

    @Test("Success shows a welcome and tells the app someone is signed in")
    func successGreetsAndSignsIn() async {
        var authenticated = false
        let viewModel = makeViewModel(loginUseCase: SpyLoginUseCase(), onAuthenticated: { authenticated = true })

        await viewModel.submit()

        #expect(authenticated)
        #expect(viewModel.confirmationMessage == "Welcome back.")
        #expect(viewModel.error == nil)
    }

    @Test("The welcome uses the name that came back on the session")
    func successGreetsByName() async {
        let getSession = StubGetSessionUseCase()
        getSession.session = .authenticated(.fixture(first: "Ada"))
        let viewModel = makeViewModel(loginUseCase: SpyLoginUseCase(), getSession: getSession)

        await viewModel.submit()

        #expect(viewModel.confirmationMessage == "Welcome back, Ada.")
    }

    @Test("A refused login says why, and nobody is told the shopper signed in")
    func aRefusedLoginSaysWhy() async {
        let loginUseCase = SpyLoginUseCase()
        loginUseCase.result = .failure(.invalidCredentials)
        var authenticated = false
        let viewModel = makeViewModel(loginUseCase: loginUseCase, onAuthenticated: { authenticated = true })

        await viewModel.submit()

        #expect(authenticated == false)
        #expect(viewModel.error == "Invalid email or password.")
        #expect(viewModel.confirmationMessage == nil)
    }
}
