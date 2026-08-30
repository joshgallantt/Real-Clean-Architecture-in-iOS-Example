import AuthUITestSupport
import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Product
import WishlistTestSupport
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Suite("The wishlist heart")
struct WishlistButtonViewModelTests {
    private func makeViewModel(
        productId: ProductID = pid(1),
        observeProductIsWishlisted: StubObserveProductIsWishlisted = StubObserveProductIsWishlisted(),
        setProductIsWishlisted: StubSetProductIsWishlisted = StubSetProductIsWishlisted(),
        authPresenter: StubAuthPresenter = StubAuthPresenter(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> WishlistButtonViewModel {
        let viewModel = WishlistButtonViewModel(
            productId: productId,
            observeProductIsWishlisted: observeProductIsWishlisted,
            setProductIsWishlisted: setProductIsWishlisted,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
        /// The screen subscribes on appear rather than in `init`, so the test has
        /// to do what the screen does before it can expect anything published.
        viewModel.onAppear()
        return viewModel
    }

    @Test("Whether the heart is filled follows what the use case already says")
    func isInWishlistFollowsTheUseCase() {
        let viewModel = makeViewModel(observeProductIsWishlisted: StubObserveProductIsWishlisted(true))

        #expect(viewModel.isInWishlist)
    }

    @Test("Appearing with something already saved is not a change the shopper watched happen")
    func appearingOnSomethingSavedDoesNotCount() {
        let viewModel = makeViewModel(observeProductIsWishlisted: StubObserveProductIsWishlisted(true))

        /// The heart bounces on this count. A card scrolling into view showing
        /// what was already true must not animate — only a change that happens
        /// while the shopper is looking at it should.
        #expect(viewModel.changes == 0)
    }

    @Test("A change while the button is on screen is one the shopper watched happen")
    func aChangeWhileShowingCounts() {
        let saved = StubObserveProductIsWishlisted(false)
        let viewModel = makeViewModel(observeProductIsWishlisted: saved)

        saved.send(true)

        #expect(viewModel.changes == 1)
    }

    @Test("The same value arriving twice is not a change")
    func theSameValueTwiceIsNotAChange() {
        let saved = StubObserveProductIsWishlisted(false)
        let viewModel = makeViewModel(observeProductIsWishlisted: saved)

        saved.send(false)

        #expect(viewModel.changes == 0)
    }

    @Test("Tapping while not saved saves it")
    func tappingWhenNotSavedSavesIt() async {
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        let viewModel = makeViewModel(
            productId: pid(1),
            setProductIsWishlisted: setProductIsWishlisted
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.map(\.productId) == [pid(1)])
        #expect(setProductIsWishlisted.calls.map(\.isWishlisted) == [true])
    }

    @Test("Tapping while already saved unsaves it")
    func tappingWhenSavedUnsavesIt() async {
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        let viewModel = makeViewModel(
            productId: pid(1),
            observeProductIsWishlisted: StubObserveProductIsWishlisted(true),
            setProductIsWishlisted: setProductIsWishlisted
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.map(\.isWishlisted) == [false])
    }

    @Test("Two taps in a row are two decisions, so it ends where it started")
    func tappingTwiceEndsWhereItStarted() async {
        let observeProductIsWishlisted = StubObserveProductIsWishlisted()
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        setProductIsWishlisted.onSuccess = { observeProductIsWishlisted.send($0) }
        let viewModel = makeViewModel(
            productId: pid(1),
            observeProductIsWishlisted: observeProductIsWishlisted,
            setProductIsWishlisted: setProductIsWishlisted
        )

        viewModel.didTap()
        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.map(\.isWishlisted) == [true, false])
        #expect(viewModel.isInWishlist == false)
    }

    @Test("Saving tells the shopper it saved")
    func savingSaysSo() async {
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.map(\.title) == ["Saved"])
    }

    @Test("Unsaving tells the shopper it is gone")
    func unsavingSaysSo() async {
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(
            observeProductIsWishlisted: StubObserveProductIsWishlisted(true),
            snackbarPresenter: snackbarPresenter
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.map(\.title) == ["Unsaved"])
    }

    @Test("A guest is asked to sign in, and saving resumes once they have")
    func guestIsAskedThenResumes() async {
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        setProductIsWishlisted.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter(onSignIn: { setProductIsWishlisted.result = .success(()) })
        authPresenter.signsIn = true
        let viewModel = makeViewModel(setProductIsWishlisted: setProductIsWishlisted, authPresenter: authPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(authPresenter.timesAsked == 1)
        #expect(setProductIsWishlisted.calls.count == 2)
    }

    @Test("A guest who backs out of signing in is not left thinking it saved")
    func guestWhoBacksOutIsNotLeftThinkingItSaved() async {
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        setProductIsWishlisted.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter()
        authPresenter.signsIn = false
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(
            setProductIsWishlisted: setProductIsWishlisted,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.isEmpty)
    }
}
