import ProductTestSupport
@testable import AuthUITestSupport
import Foundation
import SessionTestSupport
import SheetUITestSupport
import Testing
import Tracking
import TrackingTestSupport
import Session
@testable import AuthUIDI

@MainActor
@Suite("What signing in tells the shop")
struct TrackingSigningInTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let reported = SpyTrackEventUseCase()

    private func sheet(
        _ mode: AuthMode,
        login: SpyLoginUseCase,
        createAccount: SpyCreateAccountUseCase
    ) -> AuthViewModel {
        let viewModel = AuthViewModel(
            mode: mode,
            prompt: nil,
            loginUseCase: login,
            createAccountUseCase: createAccount,
            getSession: StubGetSessionUseCase(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported,
            onAuthenticated: {}
        )
        viewModel.firstName = "Ada"
        viewModel.email = "ada@example.com"
        viewModel.password = "hunter2"
        return viewModel
    }

    private let logIn = "auth_log_in"
    private let createAccount = "auth_create_account"

    @Test("The sheet opened to log in is a view of the log in screen")
    func logInScreen() {
        sheet(.logIn, login: SpyLoginUseCase(), createAccount: SpyCreateAccountUseCase()).didAppear()

        #expect(screens.events == [.screenViewed(logIn)])
    }

    @Test("Switching to creating an account is a tap on the way there, then a view of where it went")
    func switchingMode() {
        let viewModel = sheet(.logIn, login: SpyLoginUseCase(), createAccount: SpyCreateAccountUseCase())

        viewModel.switchToPeerMode()

        #expect(taps.events == [.tapped("switch_to_create_account", in: .screen(logIn))])
        #expect(screens.events == [.screenViewed(createAccount)])
    }

    @Test("A shopper who logs in is a submit, then a login by email")
    func loggingIn() async {
        await sheet(.logIn, login: SpyLoginUseCase(), createAccount: SpyCreateAccountUseCase()).submit()

        #expect(taps.events == [.tapped("submit", in: .screen(logIn))])
        #expect(reported.events == [
            TrackingEvent(name: .signedIn, context: .screen(logIn), items: [], properties: [.method: "email"])
        ])
        #expect(views.events.isEmpty)
    }

    @Test("A shopper who creates an account is a sign-up by email, not a login")
    func signingUp() async {
        await sheet(.createAccount, login: SpyLoginUseCase(), createAccount: SpyCreateAccountUseCase()).submit()

        #expect(reported.events == [
            TrackingEvent(name: .signedUp, context: .screen(createAccount), items: [], properties: [.method: "email"])
        ])
    }

    @Test("A refused login is a submit and an error seen, and nobody signed in")
    func refused() async {
        let login = SpyLoginUseCase()
        login.result = .failure(.invalidCredentials)

        await sheet(.logIn, login: login, createAccount: SpyCreateAccountUseCase()).submit()

        #expect(taps.events == [.tapped("submit", in: .screen(logIn))])
        #expect(views.events == [.viewed("auth_error", in: .screen(logIn))])
        #expect(reported.events.isEmpty)
    }

    @Test("A submit that cannot go anywhere yet is not a submit")
    func cannotSubmit() async {
        let viewModel = sheet(.logIn, login: SpyLoginUseCase(), createAccount: SpyCreateAccountUseCase())
        viewModel.password = ""

        await viewModel.submit()

        #expect(taps.events.isEmpty)
    }
}

@MainActor
@Suite("What the welcome screen tells the shop")
struct TrackingTheWelcomeScreenTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let welcome = "welcome"

    private func makeViewModel() -> WelcomeScreenViewModel {
        WelcomeScreenViewModel(
            presenter: AuthPresenter(
                sheetPresenting: SpySheetPresenting(),
                loginUseCase: SpyLoginUseCase(),
                createAccountUseCase: SpyCreateAccountUseCase(),
                getSession: StubGetSessionUseCase(.authenticated(.fixture())),
                trackScreenView: SpyTrackScreenViewUseCase(),
                trackElementView: SpyTrackElementViewUseCase(),
                trackElementInteraction: SpyTrackElementInteractionUseCase(),
                trackEvent: SpyTrackEventUseCase()
            ),
            trackScreenView: screens,
            trackElementInteraction: taps,
            onContinueAsGuest: {},
            onAuthenticated: {}
        )
    }

    @Test("Arriving is a view of the welcome screen")
    func screenView() {
        makeViewModel().didAppear(in: .screen(welcome))

        #expect(screens.events == [.screenViewed(welcome)])
    }

    @Test("Each way in is reported by its own name, on the welcome screen")
    func eachWayIn() async {
        let viewModel = makeViewModel()

        viewModel.didTapLogIn(in: .screen("welcome"))
        await viewModel.inFlight?.value
        viewModel.didTapCreateAccount(in: .screen("welcome"))
        await viewModel.inFlight?.value
        viewModel.didContinueAsGuest(in: .screen("welcome"))

        #expect(taps.events == [
            .tapped("log_in", in: .screen(welcome)),
            .tapped("create_account", in: .screen(welcome)),
            .tapped("continue_as_guest", in: .screen(welcome))
        ])
    }
}
