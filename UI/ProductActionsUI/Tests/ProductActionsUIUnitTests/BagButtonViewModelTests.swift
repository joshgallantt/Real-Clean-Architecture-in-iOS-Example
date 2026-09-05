import BagTestSupport
import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Bag
import Product
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Suite("The bag button")
struct BagButtonViewModelTests {
    private func makeViewModel(
        product: Product = .fixture(id: 1),
        observeBagItemQuantity: StubObserveBagItemQuantityUseCase = StubObserveBagItemQuantityUseCase(),
        addItemToBag: SpyAddItemToBagUseCase = SpyAddItemToBagUseCase(),
        navigation: SpyProductActionsNavigation = SpyProductActionsNavigation(),
        snackbarPresenter: SpySnackbarPresenting = SpySnackbarPresenting()
    ) -> BagButtonViewModel {
        let viewModel = BagButtonViewModel(
            product: product,
            observeBagItemQuantity: observeBagItemQuantity,
            addItemToBag: addItemToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
        /// The screen subscribes on appear rather than in `init`, so the test has
        /// to do what the screen does before it can expect anything published.
        viewModel.onAppear()
        return viewModel
    }

    @Test("The count shown follows what the bag already holds")
    func quantityFollowsTheBag() {
        let viewModel = makeViewModel(observeBagItemQuantity: StubObserveBagItemQuantityUseCase(3))

        #expect(viewModel.quantity == 3)
    }

    @Test("Tapping adds exactly one of the product, at its price, to the bag")
    func tappingAddsOneAtItsPrice() {
        let addItemToBag = SpyAddItemToBagUseCase()
        let viewModel = makeViewModel(product: .fixture(id: 1), addItemToBag: addItemToBag)

        viewModel.didTap()

        #expect(addItemToBag.added.map(\.productId) == [pid(1)])
        #expect(addItemToBag.added.map(\.quantity) == [1])
    }

    @Test("Tapping tells the shopper it is in the bag, with somewhere to go and see it")
    func tappingShowsASnackbarThatOpensTheBag() {
        let navigation = SpyProductActionsNavigation()
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(navigation: navigation, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()

        #expect(snackbarPresenter.shown.first?.title == "In the Bag")
        snackbarPresenter.shown.first?.action?.handler()
        #expect(navigation.switchedToBagTab)
    }

    @Test("A bag button can never put in something the shop cannot supply")
    func neverAddsWhatCannotBeSupplied() {
        let addItemToBag = SpyAddItemToBagUseCase()
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(
            product: .fixture(id: 1, availability: .outOfStock),
            addItemToBag: addItemToBag,
            snackbarPresenter: snackbarPresenter
        )

        viewModel.didTap()

        #expect(addItemToBag.added.isEmpty)
        #expect(snackbarPresenter.shown.isEmpty)
    }
}
