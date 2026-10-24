import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
@testable import AuthUIDI

@MainActor
@Suite("Switching between logging in and creating an account")
struct SwitchingModeTests {
    @Test("Switching goes to the other mode")
    func switchesToTheOtherMode() {
        let viewModel = AuthViewModel(
            mode: .logIn,
            prompt: nil,
            loginUseCase: SpyLoginUseCase(),
            createAccountUseCase: SpyCreateAccountUseCase(),
            getSession: StubGetSessionUseCase(),
            onAuthenticated: {}
        )

        viewModel.switchToPeerMode()

        #expect(viewModel.mode == .createAccount)
    }

    @Test("Switching clears whatever the last attempt complained about")
    func clearsError() async {
        let loginUseCase = SpyLoginUseCase()
        loginUseCase.result = .failure(.invalidCredentials)
        let viewModel = AuthViewModel(
            mode: .logIn,
            prompt: nil,
            loginUseCase: loginUseCase,
            createAccountUseCase: SpyCreateAccountUseCase(),
            getSession: StubGetSessionUseCase(),
            onAuthenticated: {}
        )
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"
        await viewModel.submit()
        #expect(viewModel.error != nil)

        viewModel.switchToPeerMode()

        #expect(viewModel.error == nil)
    }
}
