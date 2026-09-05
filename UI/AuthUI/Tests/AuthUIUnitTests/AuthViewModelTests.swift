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
