import XCTest
import SwiftUI
import SheetUI
import AuthUI
@testable import AuthUIDI

/// The sheet host is the only thing that reports dismissals back, so this stands in for it.
@MainActor
private final class SpySheetPresenting: SheetPresenting {
    private(set) var presentedCount = 0
    private(set) var dismissCount = 0
    private var onDismiss: (() -> Void)?

    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content) {
        presentedCount += 1
        self.onDismiss = onDismiss
        _ = content()
    }

    func dismiss() {
        dismissCount += 1
        onDismiss = nil
    }

    func userDismisses() {
        let handler = onDismiss
        onDismiss = nil
        handler?()
    }
}

@MainActor
final class AuthPresenterTests: XCTestCase {
    private func makeSUT(
        sheetPresenting: SheetPresenting,
        isLoggedIn: Bool
    ) -> AuthPresenter {
        AuthPresenter(
            sheetPresenting: sheetPresenting,
            userIsLoggedIn: StubUserIsLoggedInUseCase(isLoggedIn: isLoggedIn),
            loginUseCase: StubLoginUseCase(result: .success(())),
            createAccountUseCase: StubCreateAccountUseCase(result: .success(())),
            getSession: StubGetSessionUseCase(session: .josh)
        )
    }

    private func waitForPresentation(on sheet: SpySheetPresenting) async {
        while sheet.presentedCount == 0 {
            await Task.yield()
        }
    }

    func test_show_asksNothingOfAUserWhoIsAlreadyLoggedIn() async {
        let sheet = SpySheetPresenting()
        let sut = makeSUT(sheetPresenting: sheet, isLoggedIn: true)

        let outcome = await sut.show(.default)

        XCTAssertTrue(outcome)
        XCTAssertEqual(sheet.presentedCount, 0)
    }

    func test_show_presentsOneSheetForTheWholeFlow() async {
        let sheet = SpySheetPresenting()
        let sut = makeSUT(sheetPresenting: sheet, isLoggedIn: false)

        let flow = Task { await sut.show(.default) }
        await waitForPresentation(on: sheet)
        sheet.userDismisses()
        _ = await flow.value

        XCTAssertEqual(sheet.presentedCount, 1)
    }

    func test_dismissal_resolvesTheCallerAsUnauthenticated() async {
        let sheet = SpySheetPresenting()
        let sut = makeSUT(sheetPresenting: sheet, isLoggedIn: false)

        let flow = Task { await sut.show(.default) }
        await waitForPresentation(on: sheet)
        sheet.userDismisses()

        let outcome = await flow.value

        XCTAssertFalse(outcome)
    }

    func test_concurrentCallers_shareTheOneFlowAndAllHearBack() async {
        let sheet = SpySheetPresenting()
        let sut = makeSUT(sheetPresenting: sheet, isLoggedIn: false)

        let first = Task { await sut.show(.default) }
        await waitForPresentation(on: sheet)
        let second = Task { await sut.show(.default) }
        await Task.yield()
        sheet.userDismisses()

        let outcomes = await [first.value, second.value]

        XCTAssertEqual(outcomes, [false, false])
    }

    func test_directEntryPoints_openTheFlowWithoutAChooser() async {
        let sheet = SpySheetPresenting()
        let sut = makeSUT(sheetPresenting: sheet, isLoggedIn: false)

        let flow = Task { await sut.createAccount() }
        await waitForPresentation(on: sheet)
        sheet.userDismisses()
        _ = await flow.value

        XCTAssertEqual(sheet.presentedCount, 1, "One sheet, opened straight onto the step the caller asked for")
    }
}
