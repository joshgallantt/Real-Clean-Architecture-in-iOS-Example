import XCTest
import SnackbarUI
@testable import SnackbarUIDI

@MainActor
final class SnackbarPresenterTests: XCTestCase {
    func test_show_makesTheSnackbarCurrent() {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "Saved to your wishlist."))

        XCTAssertEqual(sut.current?.title, "Added")
    }

    func test_dismiss_clearsTheCurrentSnackbar() {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "Saved to your wishlist."))
        sut.dismiss()

        XCTAssertNil(sut.current)
    }

    func test_show_replacesTheSnackbarAlreadyOnScreen() {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "m"))
        sut.show(Snackbar(title: "Removed", message: "m"))

        XCTAssertEqual(sut.current?.title, "Removed")
    }

    func test_performAction_runsTheHandlerAndRetiresTheSnackbar() {
        let sut = SnackbarPresenter()
        var undone = false

        sut.show(Snackbar(title: "Added", message: "m", action: .undo { undone = true }))
        sut.performAction()

        XCTAssertTrue(undone)
        XCTAssertNil(sut.current)
    }

    func test_performAction_withoutAnAction_justRetiresTheSnackbar() {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "m"))
        sut.performAction()

        XCTAssertNil(sut.current)
    }

    func test_autoHide_retiresTheSnackbarOnceItsDurationElapses() async throws {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "m"))
        try await Task.sleep(for: .seconds(2.2))

        XCTAssertNil(sut.current)
    }

    func test_autoHide_forASupersededSnackbarDoesNotRetireItsReplacement() async throws {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "First", message: "m"))
        try await Task.sleep(for: .seconds(1.5))
        sut.show(Snackbar(title: "Second", message: "m"))
        try await Task.sleep(for: .seconds(1))

        XCTAssertEqual(sut.current?.title, "Second", "The first snackbar's timer must not retire the second")
    }
}
