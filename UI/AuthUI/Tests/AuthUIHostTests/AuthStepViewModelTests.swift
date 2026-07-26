import XCTest
import Session
@testable import AuthUIDI

@MainActor
final class AuthStepViewModelTests: XCTestCase {
    func test_logIn_holdsTheButtonBackUntilBothFieldsAreFilled() {
        let sut = makeLogInStep()

        XCTAssertFalse(sut.canSubmit)

        sut.email = "josh@example.com"

        XCTAssertFalse(sut.canSubmit)

        sut.password = "hunter2"

        XCTAssertTrue(sut.canSubmit)
    }

    func test_createAccount_doesNotWaitForALastName() {
        let sut = makeCreateAccountStep()
        sut.firstName = "Josh"
        sut.email = "josh@example.com"
        sut.password = "hunter2"

        XCTAssertTrue(sut.canSubmit, "The domain accepts an empty last name, so the button should too")
    }

    func test_createAccount_waitsForEveryFieldTheDomainRequires() {
        let sut = makeCreateAccountStep()
        sut.lastName = "Gallant"

        XCTAssertFalse(sut.canSubmit)
    }

    func test_aStepInFlightWillNotSubmitAgain() async {
        let sut = makeLogInStep()
        sut.email = "josh@example.com"
        sut.password = "hunter2"
        sut.isLoading = true

        XCTAssertFalse(sut.canSubmit)
    }

    func test_greetingUsesTheNameOnTheSessionTheLoginProduced() async {
        let sut = makeLogInStep(result: .success(()), session: .josh)

        await sut.logIn()

        XCTAssertEqual(sut.confirmation?.message, "Welcome back, Josh.")
    }

    func test_greetingStillReadsWhenTheSessionHasNoName() async {
        let sut = makeCreateAccountStep(result: .success(()), session: .guest)

        await sut.createAccount()

        XCTAssertEqual(sut.confirmation?.message, "Welcome.")
    }

    func test_aFailedAttemptLeavesTheFormUsable() async {
        let sut = makeCreateAccountStep(result: .failure(.emailAlreadyInUse))
        sut.firstName = "Josh"
        sut.email = "josh@example.com"
        sut.password = "hunter2"

        await sut.createAccount()

        XCTAssertNil(sut.confirmation)
        XCTAssertEqual(sut.error, "An account with this email already exists.")
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.canSubmit)
    }
}
