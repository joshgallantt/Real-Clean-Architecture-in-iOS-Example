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
        addProductToWishlist: StubAddProductToWishlist = StubAddProductToWishlist(),
        removeProductFromWishlist: StubRemoveProductFromWishlist = StubRemoveProductFromWishlist(),
        authPresenter: StubAuthPresenter = StubAuthPresenter(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> WishlistButtonViewModel {
        WishlistButtonViewModel(
            productId: productId,
            observeProductIsWishlisted: observeProductIsWishlisted,
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter
        )
    }

    @Test("Whether the heart is filled follows what the use case already says")
    func isInWishlistFollowsTheUseCase() {
        let viewModel = makeViewModel(observeProductIsWishlisted: StubObserveProductIsWishlisted(true))

        #expect(viewModel.isInWishlist)
    }

    @Test("Tapping while not saved adds it, and only it")
    func tappingWhenNotSavedAddsIt() async {
        let addProductToWishlist = StubAddProductToWishlist()
        let removeProductFromWishlist = StubRemoveProductFromWishlist()
        let viewModel = makeViewModel(
            productId: pid(1),
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist
        )

        viewModel.didTap()
        await settle()

        #expect(addProductToWishlist.calls == [pid(1)])
        #expect(removeProductFromWishlist.calls.isEmpty)
    }

    @Test("Tapping while already saved removes it, and only it")
    func tappingWhenSavedRemovesIt() async {
        let addProductToWishlist = StubAddProductToWishlist()
        let removeProductFromWishlist = StubRemoveProductFromWishlist()
        let viewModel = makeViewModel(
            productId: pid(1),
            observeProductIsWishlisted: StubObserveProductIsWishlisted(true),
            addProductToWishlist: addProductToWishlist,
            removeProductFromWishlist: removeProductFromWishlist
        )

        viewModel.didTap()
        await settle()

        #expect(removeProductFromWishlist.calls == [pid(1)])
        #expect(addProductToWishlist.calls.isEmpty)
    }

    @Test("Saving shows a snackbar that can undo it")
    func savingOffersUndo() async {
        let removeProductFromWishlist = StubRemoveProductFromWishlist()
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(removeProductFromWishlist: removeProductFromWishlist, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await settle()

        #expect(snackbarPresenter.shown.first?.title == "Saved")
        snackbarPresenter.shown.first?.action?.handler()
        await settle()
        #expect(removeProductFromWishlist.calls == [pid(1)])
    }

    @Test("A guest is asked to sign in, and saving resumes once they have")
    func guestIsAskedThenResumes() async {
        let addProductToWishlist = StubAddProductToWishlist()
        addProductToWishlist.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter(onSignIn: { addProductToWishlist.result = .success(()) })
        authPresenter.signsIn = true
        let viewModel = makeViewModel(addProductToWishlist: addProductToWishlist, authPresenter: authPresenter)

        viewModel.didTap()
        await settle()

        #expect(authPresenter.timesAsked == 1)
        #expect(addProductToWishlist.calls.count == 2)
    }

    @Test("A guest who backs out of signing in is not left thinking it saved")
    func guestWhoBacksOutIsNotLeftThinkingItSaved() async {
        let addProductToWishlist = StubAddProductToWishlist()
        addProductToWishlist.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter()
        authPresenter.signsIn = false
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(addProductToWishlist: addProductToWishlist, authPresenter: authPresenter, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()
        await settle()

        #expect(snackbarPresenter.shown.isEmpty)
    }
}
