import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
@testable import AuthUIDI

@MainActor
@Suite("Whether there is something a shopper would lose by leaving")
struct HasUnsavedInputTests {
    private func makeViewModel() -> AuthViewModel {
        AuthViewModel(
            mode: .logIn,
            prompt: nil,
            loginUseCase: SpyLoginUseCase(),
            createAccountUseCase: SpyCreateAccountUseCase(),
            getSession: StubGetSessionUseCase(),
            onAuthenticated: {}
        )
    }

    @Test("A blank form has nothing to lose")
    func aBlankFormHasNothingToLose() {
        #expect(makeViewModel().hasUnsavedInput == false)
    }

    @Test("Anything typed is something that would be lost")
    func anythingTypedWouldBeLost() {
        let viewModel = makeViewModel()
        viewModel.email = "a"
        #expect(viewModel.hasUnsavedInput)
    }

    @Test("Once it has succeeded, there is nothing left to lose")
    func nothingIsLeftToLoseOnceItHasSucceeded() async {
        let viewModel = makeViewModel()
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"

        await viewModel.submit()

        #expect(viewModel.hasUnsavedInput == false)
    }
}
