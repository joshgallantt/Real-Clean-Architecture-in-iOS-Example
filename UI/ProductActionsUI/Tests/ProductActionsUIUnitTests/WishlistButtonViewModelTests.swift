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
        observeProductIsWishlisted: StubObserveProductIsWishlistedUseCase = StubObserveProductIsWishlistedUseCase(),
        setProductIsWishlisted: SpySetProductIsWishlistedUseCase = SpySetProductIsWishlistedUseCase(),
        authPresenter: SpyAuthPresenting = SpyAuthPresenting(),
        snackbarPresenter: SpySnackbarPresenting = SpySnackbarPresenting()
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
        let viewModel = makeViewModel(observeProductIsWishlisted: StubObserveProductIsWishlistedUseCase(true))

        #expect(viewModel.isInWishlist)
    }

    @Test("Tapping while not saved saves it")
    func tappingWhenNotSavedSavesIt() async {
        let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
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
        let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
        let viewModel = makeViewModel(
            productId: pid(1),
            observeProductIsWishlisted: StubObserveProductIsWishlistedUseCase(true),
            setProductIsWishlisted: setProductIsWishlisted
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.map(\.isWishlisted) == [false])
    }

    @Test("Two taps in a row are two decisions, so it ends where it started")
    func tappingTwiceEndsWhereItStarted() async {
        let observeProductIsWishlisted = StubObserveProductIsWishlistedUseCase()
        let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
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
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.map(\.title) == ["Saved"])
    }

    @Test("Unsaving tells the shopper it is gone")
    func unsavingSaysSo() async {
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(
            observeProductIsWishlisted: StubObserveProductIsWishlistedUseCase(true),
            snackbarPresenter: snackbarPresenter
        )

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(snackbarPresenter.shown.map(\.title) == ["Unsaved"])
    }

    @Test("A guest is asked to sign in, and saving resumes once they have")
    func guestIsAskedThenResumes() async {
        let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
        setProductIsWishlisted.result = .failure(.unauthenticated)
        let authPresenter = SpyAuthPresenting(onSignIn: { setProductIsWishlisted.result = .success(()) })
        authPresenter.signsIn = true
        let viewModel = makeViewModel(setProductIsWishlisted: setProductIsWishlisted, authPresenter: authPresenter)

        viewModel.didTap()
        await viewModel.inFlight?.value

        #expect(authPresenter.timesAsked == 1)
        #expect(setProductIsWishlisted.calls.count == 2)
    }

    @Test("A guest who backs out of signing in is not left thinking it saved")
    func guestWhoBacksOutIsNotLeftThinkingItSaved() async {
        let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
        setProductIsWishlisted.result = .failure(.unauthenticated)
        let authPresenter = SpyAuthPresenting()
        authPresenter.signsIn = false
        let snackbarPresenter = SpySnackbarPresenting()
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
