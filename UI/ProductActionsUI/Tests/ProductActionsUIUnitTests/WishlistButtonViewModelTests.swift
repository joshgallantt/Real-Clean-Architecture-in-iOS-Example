import Foundation
import Testing
import Product
@testable import ProductActionsUI

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
        WishlistButtonViewModel(
            productId: productId,
            observeProductIsWishlisted: observeProductIsWishlisted,
            setProductIsWishlisted: setProductIsWishlisted,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }

    @Test("Whether the heart is filled follows what the use case already says")
    func isInWishlistFollowsTheUseCase() {
        let viewModel = makeViewModel(observeProductIsWishlisted: StubObserveProductIsWishlisted(true))

        #expect(viewModel.isInWishlist)
    }

    @Test("Tapping while not saved saves it")
    func tappingWhenNotSavedSavesIt() async {
        let setProductIsWishlisted = StubSetProductIsWishlisted()
        let viewModel = makeViewModel(
            productId: pid(1),
            setProductIsWishlisted: setProductIsWishlisted
        )

        viewModel.didTap()
        await settle()

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
        await settle()

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
        await settle()

        #expect(setProductIsWishlisted.calls.map(\.isWishlisted) == [true, false])
        #expect(viewModel.isInWishlist == false)
    }

    @Test("Saving tells the shopper it saved")
    func savingSaysSo() async {
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await settle()

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
        await settle()

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
        await settle()

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
        await settle()

        #expect(snackbarPresenter.shown.isEmpty)
    }
}
