import AuthUITestSupport
import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import WaitlistTestSupport
import Testing
import Product
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Suite("The stock alert bell")
struct StockAlertButtonViewModelTests {
    private func makeViewModel(
        productId: ProductID = pid(1),
        observeProductIsWaitlisted: StubObserveProductIsWaitlistedUseCase = StubObserveProductIsWaitlistedUseCase(),
        setProductIsWaitlisted: SpySetProductIsWaitlistedUseCase = SpySetProductIsWaitlistedUseCase(),
        authPresenter: SpyAuthPresenting = SpyAuthPresenting(),
        snackbarPresenter: SpySnackbarPresenting = SpySnackbarPresenting()
    ) -> StockAlertButtonViewModel {
        let viewModel = StockAlertButtonViewModel(
            productId: productId,
            observeProductIsWaitlisted: observeProductIsWaitlisted,
            setProductIsWaitlisted: setProductIsWaitlisted,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
        /// The screen subscribes on appear rather than in `init`, so the test has
        /// to do what the screen does before it can expect anything published.
        viewModel.onAppear()
        return viewModel
    }

    @Test("Whether the bell shows waiting follows what the use case already says")
    func isWaitingFollowsTheUseCase() {
        let viewModel = makeViewModel(observeProductIsWaitlisted: StubObserveProductIsWaitlistedUseCase(true))

        #expect(viewModel.isWaiting)
    }

    @Test("Tapping while not on the list asks to be put on it")
    func tapWhenNotWaitingAsksToBeAdded() async {
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        let viewModel = makeViewModel(
            productId: pid(1),
            observeProductIsWaitlisted: StubObserveProductIsWaitlistedUseCase(false),
            setProductIsWaitlisted: setProductIsWaitlisted
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.map(\.productId) == [pid(1)])
        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [true])
    }

    @Test("Tapping while already on the list asks to come off it")
    func tapWhenWaitingAsksToBeRemoved() async {
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        let viewModel = makeViewModel(observeProductIsWaitlisted: StubObserveProductIsWaitlistedUseCase(true), setProductIsWaitlisted: setProductIsWaitlisted)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [false])
    }

    @Test("Two taps in a row are two decisions, so it ends where it started")
    func tappingTwiceEndsWhereItStarted() async {
        let observeProductIsWaitlisted = StubObserveProductIsWaitlistedUseCase(false)
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        setProductIsWaitlisted.onSuccess = { observeProductIsWaitlisted.send($0) }
        let viewModel = makeViewModel(
            observeProductIsWaitlisted: observeProductIsWaitlisted,
            setProductIsWaitlisted: setProductIsWaitlisted
        )

        viewModel.didTap()
        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [true, false])
        #expect(viewModel.isWaiting == false)
    }

    @Test("Removing waits its turn, and still takes it off whatever the bell says")
    func removeAfterATapStillTurnsItOff() async {
        let observeProductIsWaitlisted = StubObserveProductIsWaitlistedUseCase(false)
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        setProductIsWaitlisted.onSuccess = { observeProductIsWaitlisted.send($0) }
        let viewModel = makeViewModel(
            observeProductIsWaitlisted: observeProductIsWaitlisted,
            setProductIsWaitlisted: setProductIsWaitlisted
        )

        viewModel.didTap()
        viewModel.didTapRemove()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [true, false])
        #expect(viewModel.isWaiting == false)
    }

    @Test("Removing always takes it off the list, whatever the bell currently says")
    func didTapRemoveAlwaysTurnsItOff() async {
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        let viewModel = makeViewModel(observeProductIsWaitlisted: StubObserveProductIsWaitlistedUseCase(false), setProductIsWaitlisted: setProductIsWaitlisted)

        viewModel.didTapRemove()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [false])
    }

    @Test("Success is confirmed with a snackbar")
    func successShowsASnackbar() async {
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.first?.title == "You're on the List")
    }

    @Test("A guest is asked to sign in, and the ask resumes once they have")
    func guestIsAskedThenResumes() async {
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        setProductIsWaitlisted.result = .failure(.unauthenticated)
        let authPresenter = SpyAuthPresenting(onSignIn: { setProductIsWaitlisted.result = .success(()) })
        authPresenter.signsIn = true
        let viewModel = makeViewModel(setProductIsWaitlisted: setProductIsWaitlisted, authPresenter: authPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(authPresenter.timesAsked == 1)
        #expect(setProductIsWaitlisted.calls.count == 2)
        #expect(setProductIsWaitlisted.calls.map(\.isWaitlisted) == [true, true])
    }

    @Test("A guest who backs out is not left thinking they are on the list")
    func guestWhoBacksOutIsNotOnTheList() async {
        let setProductIsWaitlisted = SpySetProductIsWaitlistedUseCase()
        setProductIsWaitlisted.result = .failure(.unauthenticated)
        let authPresenter = SpyAuthPresenting()
        authPresenter.signsIn = false
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(setProductIsWaitlisted: setProductIsWaitlisted, authPresenter: authPresenter, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWaitlisted.calls.count == 1)
        #expect(snackbarPresenter.shown.isEmpty)
    }
}
