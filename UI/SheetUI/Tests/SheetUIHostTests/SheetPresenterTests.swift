import XCTest
import SwiftUI
@testable import SheetUIDI

/// The host (`.sheetHost`) is the only thing that reports dismissals back, so these tests
/// stand in for it: clear `presentation` the way SwiftUI does on an interactive dismissal,
/// then deliver the `onDismiss` callback.
@MainActor
final class SheetPresenterTests: XCTestCase {
    private func userDismissesSheet(on sut: SheetPresenter) {
        sut.presentation = nil
        sut.sheetDidDismiss()
    }

    /// SwiftUI reports the outgoing sheet's dismissal after the presenter has already
    /// cleared it to make way for a successor.
    private func hostFinishesDismissing(on sut: SheetPresenter) {
        sut.sheetDidDismiss()
    }

    func test_present_showsContent() {
        let sut = SheetPresenter()

        sut.present(onDismiss: nil, content: { Text("hello") })

        XCTAssertNotNil(sut.presentation)
    }

    func test_userDismissal_firesOnDismiss() {
        let sut = SheetPresenter()
        var dismissed = false

        sut.present(onDismiss: { dismissed = true }, content: { Text("hello") })
        userDismissesSheet(on: sut)

        XCTAssertTrue(dismissed)
        XCTAssertNil(sut.presentation)
    }

    func test_programmaticDismiss_doesNotFireOnDismiss() {
        let sut = SheetPresenter()
        var dismissed = false

        sut.present(onDismiss: { dismissed = true }, content: { Text("hello") })
        sut.dismiss()
        hostFinishesDismissing(on: sut)

        XCTAssertFalse(dismissed)
        XCTAssertNil(sut.presentation)
    }

    func test_chaining_doesNotFireSupersededSheetsOnDismiss() {
        let sut = SheetPresenter()
        var firstDismissed = false

        sut.present(onDismiss: { firstDismissed = true }, content: { Text("gate") })
        sut.present(onDismiss: {}, content: { Text("login") })
        hostFinishesDismissing(on: sut)

        XCTAssertFalse(firstDismissed, "Chaining to a new sheet must not resolve the sheet it replaced")
        XCTAssertNotNil(sut.presentation, "The queued sheet should be on screen once the first finishes dismissing")
    }

    func test_chaining_firesTheSuccessorsOnDismissWhenTheUserEndsIt() {
        let sut = SheetPresenter()
        var secondDismissed = false

        sut.present(onDismiss: {}, content: { Text("gate") })
        sut.present(onDismiss: { secondDismissed = true }, content: { Text("login") })
        hostFinishesDismissing(on: sut)

        XCTAssertFalse(secondDismissed)

        userDismissesSheet(on: sut)

        XCTAssertTrue(secondDismissed)
        XCTAssertNil(sut.presentation)
    }

    func test_dismiss_dropsAQueuedSheet() {
        let sut = SheetPresenter()

        sut.present(onDismiss: {}, content: { Text("gate") })
        sut.present(onDismiss: {}, content: { Text("login") })
        sut.dismiss()
        hostFinishesDismissing(on: sut)

        XCTAssertNil(sut.presentation)
    }
}
