import Foundation
import Testing
import Session
import SheetUI
@testable import AuthUIDI

@MainActor
@Suite("The welcome screen")
struct WelcomeScreenViewModelTests {
    private func makePresenter(
        getSession: StubGetSession = StubGetSession(),
        sheetPresenting: SpySheetPresenter = SpySheetPresenter()
    ) -> AuthPresenter {
        AuthPresenter(
            sheetPresenting: sheetPresenting,
            loginUseCase: StubLogin(),
            createAccountUseCase: StubCreateAccount(),
            getSession: getSession
        )
    }

    @Test("Continuing as a guest tells the app so, without presenting anything to sign in with")
    func continuingAsGuest() {
        let sheetPresenting = SpySheetPresenter()
        var continuedAsGuest = false
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(sheetPresenting: sheetPresenting),
            onContinueAsGuest: { continuedAsGuest = true },
            onAuthenticated: { authenticated = true }
        )

        viewModel.didContinueAsGuest()

        #expect(continuedAsGuest)
        #expect(authenticated == false)
        #expect(sheetPresenting.presentCount == 0)
    }

    @Test("Tapping Log In while already signed in needs no sheet at all")
    func logInWhenAlreadySignedIn() async {
        let getSession = StubGetSession()
        getSession.session = .authenticated(.fixture())
        let sheetPresenting = SpySheetPresenter()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(getSession: getSession, sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapLogIn()
        await settle()

        #expect(authenticated)
        #expect(sheetPresenting.presentCount == 0)
    }

    @Test("A guest who backs out of the sheet is not told they are authenticated")
    func logInBackingOut() async {
        let sheetPresenting = SpySheetPresenter()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapLogIn()
        await settle()
        sheetPresenting.userDismissedTheSheet()
        await settle()

        #expect(sheetPresenting.presentCount == 1)
        #expect(authenticated == false)
    }

    @Test("Tapping Create Account while already signed in needs no sheet at all")
    func createAccountWhenAlreadySignedIn() async {
        let getSession = StubGetSession()
        getSession.session = .authenticated(.fixture())
        let sheetPresenting = SpySheetPresenter()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(getSession: getSession, sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapCreateAccount()
        await settle()

        #expect(authenticated)
        #expect(sheetPresenting.presentCount == 0)
    }
}
