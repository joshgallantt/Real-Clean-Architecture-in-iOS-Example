import XCTest
import SnackbarUI

final class SnackbarTests: XCTestCase {
    func test_displayDuration_isShortWhenThereIsNothingToActOn() {
        let snackbar = Snackbar(title: "Added", message: "m")

        XCTAssertEqual(snackbar.displayDuration, .seconds(2))
    }

    func test_displayDuration_isLongerWhenThereIsAnActionToConsider() {
        let snackbar = Snackbar(title: "Added", message: "m", action: .undo {})

        XCTAssertEqual(snackbar.displayDuration, .seconds(3.5))
    }

    func test_namedActions_carryTheirConventionalLabels() {
        XCTAssertEqual(SnackbarAction.undo {}.label, "Undo")
        XCTAssertEqual(SnackbarAction.retry {}.label, "Retry")
    }
}
