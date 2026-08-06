import Foundation
import Testing
import Product
@testable import ProductActionsUI

@MainActor
@Suite("The stock alert bell")
struct StockAlertButtonViewModelTests {
    private func makeViewModel(
        productId: ProductID = pid(1),
        observeWaitlistStatus: StubObserveWaitlistStatus = StubObserveWaitlistStatus(),
        setStockAlert: StubSetStockAlert = StubSetStockAlert(),
        authPresenter: StubAuthPresenter = StubAuthPresenter(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> StockAlertButtonViewModel {
        StockAlertButtonViewModel(
            productId: productId,
            observeWaitlistStatus: observeWaitlistStatus,
            setStockAlert: setStockAlert,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }

    @Test("Whether the bell shows waiting follows what the use case already says")
    func isWaitingFollowsTheUseCase() {
        let viewModel = makeViewModel(observeWaitlistStatus: StubObserveWaitlistStatus(true))

        #expect(viewModel.isWaiting)
    }

    @Test("Tapping while not on the list asks to be put on it")
    func tapWhenNotWaitingAsksToBeAdded() async {
        let setStockAlert = StubSetStockAlert()
        let viewModel = makeViewModel(
            productId: pid(1),
            observeWaitlistStatus: StubObserveWaitlistStatus(false),
            setStockAlert: setStockAlert
        )

        viewModel.didTap()
        await settle()

        #expect(setStockAlert.calls.map(\.productId) == [pid(1)])
        #expect(setStockAlert.calls.map(\.isOn) == [true])
    }

    @Test("Tapping while already on the list asks to come off it")
    func tapWhenWaitingAsksToBeRemoved() async {
        let setStockAlert = StubSetStockAlert()
        let viewModel = makeViewModel(observeWaitlistStatus: StubObserveWaitlistStatus(true), setStockAlert: setStockAlert)

        viewModel.didTap()
        await settle()

        #expect(setStockAlert.calls.map(\.isOn) == [false])
    }

    @Test("Two taps in a row are two decisions, so it ends where it started")
    func tappingTwiceEndsWhereItStarted() async {
        let observeWaitlistStatus = StubObserveWaitlistStatus(false)
        let setStockAlert = StubSetStockAlert()
        setStockAlert.onSuccess = { observeWaitlistStatus.send($0) }
        let viewModel = makeViewModel(
            observeWaitlistStatus: observeWaitlistStatus,
            setStockAlert: setStockAlert
        )

        viewModel.didTap()
        viewModel.didTap()
        await settle()

        #expect(setStockAlert.calls.map(\.isOn) == [true, false])
        #expect(viewModel.isWaiting == false)
    }

    @Test("Removing waits its turn, and still takes it off whatever the bell says")
    func removeAfterATapStillTurnsItOff() async {
        let observeWaitlistStatus = StubObserveWaitlistStatus(false)
        let setStockAlert = StubSetStockAlert()
        setStockAlert.onSuccess = { observeWaitlistStatus.send($0) }
        let viewModel = makeViewModel(
            observeWaitlistStatus: observeWaitlistStatus,
            setStockAlert: setStockAlert
        )

        viewModel.didTap()
        viewModel.didTapRemove()
        await settle()

        #expect(setStockAlert.calls.map(\.isOn) == [true, false])
        #expect(viewModel.isWaiting == false)
    }

    @Test("Removing always takes it off the list, whatever the bell currently says")
    func didTapRemoveAlwaysTurnsItOff() async {
        let setStockAlert = StubSetStockAlert()
        let viewModel = makeViewModel(observeWaitlistStatus: StubObserveWaitlistStatus(false), setStockAlert: setStockAlert)

        viewModel.didTapRemove()
        await settle()

        #expect(setStockAlert.calls.map(\.isOn) == [false])
    }

    @Test("Success is confirmed with a snackbar")
    func successShowsASnackbar() async {
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await settle()

        #expect(snackbarPresenter.shown.first?.title == "You're on the List")
    }

    @Test("A guest is asked to sign in, and the ask resumes once they have")
    func guestIsAskedThenResumes() async {
        let setStockAlert = StubSetStockAlert()
        setStockAlert.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter(onSignIn: { setStockAlert.result = .success(()) })
        authPresenter.signsIn = true
        let viewModel = makeViewModel(setStockAlert: setStockAlert, authPresenter: authPresenter)

        viewModel.didTap()
        await settle()

        #expect(authPresenter.timesAsked == 1)
        #expect(setStockAlert.calls.count == 2)
        #expect(setStockAlert.calls.map(\.isOn) == [true, true])
    }

    @Test("A guest who backs out is not left thinking they are on the list")
    func guestWhoBacksOutIsNotOnTheList() async {
        let setStockAlert = StubSetStockAlert()
        setStockAlert.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter()
        authPresenter.signsIn = false
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(setStockAlert: setStockAlert, authPresenter: authPresenter, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await settle()

        #expect(setStockAlert.calls.count == 1)
        #expect(snackbarPresenter.shown.isEmpty)
    }
}
