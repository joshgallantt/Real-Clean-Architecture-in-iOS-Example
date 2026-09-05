import ProductTestSupport
import SheetUITestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import Testing
import Session
import SheetUI
@testable import AuthUIDI

@MainActor
@Suite("The welcome screen")
struct WelcomeScreenViewModelTests {
    private func makePresenter(
        getSession: StubGetSessionUseCase = StubGetSessionUseCase(),
        sheetPresenting: SpySheetPresenting = SpySheetPresenting()
    ) -> AuthPresenter {
        AuthPresenter(
            sheetPresenting: sheetPresenting,
            loginUseCase: SpyLoginUseCase(),
            createAccountUseCase: SpyCreateAccountUseCase(),
            getSession: getSession
        )
    }

    @Test("Continuing as a guest tells the app so, without presenting anything to sign in with")
    func continuingAsGuest() {
        let sheetPresenting = SpySheetPresenting()
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
        let getSession = StubGetSessionUseCase()
        getSession.session = .authenticated(.fixture())
        let sheetPresenting = SpySheetPresenting()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(getSession: getSession, sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapLogIn()
        await viewModel.inFlight?.value

        #expect(authenticated)
        #expect(sheetPresenting.presentCount == 0)
    }

    @Test("A guest who backs out of the sheet is not told they are authenticated")
    func logInBackingOut() async {
        let sheetPresenting = SpySheetPresenting()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapLogIn()
        await sheetPresenting.untilPresented()
        sheetPresenting.userDismissedTheSheet()
        await viewModel.inFlight?.value

        #expect(sheetPresenting.presentCount == 1)
        #expect(authenticated == false)
    }

    @Test("Tapping Create Account while already signed in needs no sheet at all")
    func createAccountWhenAlreadySignedIn() async {
        let getSession = StubGetSessionUseCase()
        getSession.session = .authenticated(.fixture())
        let sheetPresenting = SpySheetPresenting()
        var authenticated = false
        let viewModel = WelcomeScreenViewModel(
            presenter: makePresenter(getSession: getSession, sheetPresenting: sheetPresenting),
            onContinueAsGuest: {},
            onAuthenticated: { authenticated = true }
        )

        viewModel.didTapCreateAccount()
        await viewModel.inFlight?.value

        #expect(authenticated)
        #expect(sheetPresenting.presentCount == 0)
    }
}
