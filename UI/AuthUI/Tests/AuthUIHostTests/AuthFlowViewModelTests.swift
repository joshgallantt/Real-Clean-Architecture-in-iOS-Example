import XCTest
import AuthUI
@testable import AuthUIDI

@MainActor
final class AuthFlowViewModelTests: XCTestCase {
    private func makeSUT(
        step: AuthenticationStep = .logIn,
        prompt: AuthenticationPrompt? = nil,
        logIn: LogInStepViewModel? = nil,
        createAccount: CreateAccountStepViewModel? = nil,
        onAuthenticated: @escaping () -> Void = {}
    ) -> AuthFlowViewModel {
        AuthFlowViewModel(
            step: step,
            prompt: prompt,
            logIn: logIn ?? makeLogInStep(),
            createAccount: createAccount ?? makeCreateAccountStep(),
            onAuthenticated: onAuthenticated
        )
    }

    func test_showPeer_swapsToTheOtherFormAndBackAgain() {
        let sut = makeSUT(step: .logIn)

        sut.showPeer()

        XCTAssertEqual(sut.step, .createAccount)

        sut.showPeer()

        XCTAssertEqual(sut.step, .logIn, "The peer link is the way back as well as the way there")
    }

    func test_header_prefersThePromptTheFeatureSupplied() {
        let prompt = AuthenticationPrompt(
            title: "Save to Wishlist",
            message: "Log in to keep this item.",
            icon: "heart.fill"
        )
        let sut = makeSUT(step: .logIn, prompt: prompt)

        XCTAssertEqual(sut.header, AuthHeader(prompt))
    }

    func test_header_dropsThePromptOnceTheUserMovesToTheOtherForm() {
        let prompt = AuthenticationPrompt(message: "Log in to keep this item.")
        let sut = makeSUT(step: .logIn, prompt: prompt)

        sut.showPeer()

        XCTAssertEqual(sut.header, AuthenticationStep.createAccount.header)
    }

    func test_header_fallsBackToTheStepsOwnWords() {
        let sut = makeSUT(step: .createAccount, prompt: nil)

        XCTAssertEqual(sut.header, AuthenticationStep.createAccount.header)
    }

    func test_hasUnsavedInput_isFalseUntilSomethingIsTyped() {
        let sut = makeSUT()

        XCTAssertFalse(sut.hasUnsavedInput)
    }

    func test_hasUnsavedInput_seesInputOnEitherStep() {
        let createAccount = makeCreateAccountStep()
        let sut = makeSUT(createAccount: createAccount)

        createAccount.firstName = "Josh"

        XCTAssertTrue(sut.hasUnsavedInput)
    }

    func test_closeRequested_asksBeforeDiscardingTypedInput() {
        let logIn = makeLogInStep()
        let sut = makeSUT(logIn: logIn)
        logIn.email = "josh@example.com"

        XCTAssertFalse(sut.closeRequested(), "Closing has to wait on the confirmation")
        XCTAssertTrue(sut.isConfirmingDiscard)
    }

    func test_closeRequested_closesStraightAwayWithNothingToLose() {
        let sut = makeSUT()

        XCTAssertTrue(sut.closeRequested())
        XCTAssertFalse(sut.isConfirmingDiscard)
    }

    func test_confirmation_surfacesFromWhicheverStepSucceeded() async {
        let createAccount = makeCreateAccountStep(result: .success(()))
        let sut = makeSUT(step: .logIn, createAccount: createAccount)

        await createAccount.createAccount()

        XCTAssertEqual(sut.confirmation?.title, "Account Created")
        XCTAssertEqual(sut.confirmation?.message, "Welcome, Josh.")
    }

    func test_confirmation_stopsGuardingInputOnceTheUserIsThrough() async {
        let logIn = makeLogInStep(result: .success(()))
        let sut = makeSUT(logIn: logIn)
        logIn.email = "josh@example.com"
        logIn.password = "hunter2"

        await logIn.logIn()

        XCTAssertNotNil(sut.confirmation)
        XCTAssertFalse(sut.hasUnsavedInput, "The fields have served their purpose by now")
    }

    func test_onAuthenticated_firesOnceWhenAStepSucceeds() async {
        let logIn = makeLogInStep(result: .success(()))
        var authenticatedCount = 0
        let sut = makeSUT(logIn: logIn, onAuthenticated: { authenticatedCount += 1 })

        await logIn.logIn()
        await logIn.logIn()

        XCTAssertEqual(authenticatedCount, 1)
        XCTAssertNotNil(sut.confirmation)
    }

    func test_onAuthenticated_staysQuietWhenAStepFails() async {
        let logIn = makeLogInStep(result: .failure(.invalidCredentials))
        var authenticated = false
        let sut = makeSUT(logIn: logIn, onAuthenticated: { authenticated = true })

        await logIn.logIn()

        XCTAssertFalse(authenticated)
        XCTAssertNil(sut.confirmation)
        XCTAssertEqual(logIn.error, "Invalid email or password.")
    }
}
