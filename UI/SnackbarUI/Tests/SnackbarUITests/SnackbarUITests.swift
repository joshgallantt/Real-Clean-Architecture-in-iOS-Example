import XCTest
@testable import SnackbarUI

final class SnackbarUITests: XCTestCase {
    @MainActor
    func test_show_setsCurrent_andDismissClearsIt() {
        let sut = SnackbarPresenter()

        sut.show(Snackbar(title: "Added", message: "Saved to your wishlist."))
        XCTAssertEqual(sut.current?.title, "Added")

        sut.dismiss()
        XCTAssertNil(sut.current)
    }

    @MainActor
    func test_performAction_runsHandlerAndDismisses() {
        let sut = SnackbarPresenter()
        var undone = false

        sut.show(Snackbar(title: "Added", message: "m", action: .undo { undone = true }))
        sut.performAction()

        XCTAssertTrue(undone)
        XCTAssertNil(sut.current)
    }
}
