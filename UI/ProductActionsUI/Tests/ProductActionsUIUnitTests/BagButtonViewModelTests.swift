import Foundation
import Testing
import Bag
import Product
@testable import ProductActionsUI

@MainActor
@Suite("The bag button")
struct BagButtonViewModelTests {
    private func makeViewModel(
        product: Product = .fixture(id: 1),
        observeBagItemQuantity: StubObserveBagItemQuantity = StubObserveBagItemQuantity(),
        addItemToBag: SpyAddItemToBag = SpyAddItemToBag(),
        navigation: SpyProductActionsNavigation = SpyProductActionsNavigation(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            observeBagItemQuantity: observeBagItemQuantity,
            addItemToBag: addItemToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
    }

    @Test("The count shown follows what the bag already holds")
    func quantityFollowsTheBag() {
        let viewModel = makeViewModel(observeBagItemQuantity: StubObserveBagItemQuantity(3))

        #expect(viewModel.quantity == 3)
    }

    @Test("Tapping adds exactly one of the product, at its price, to the bag")
    func tappingAddsOneAtItsPrice() {
        let addItemToBag = SpyAddItemToBag()
        let viewModel = makeViewModel(product: .fixture(id: 1), addItemToBag: addItemToBag)

        viewModel.didTap()

        #expect(addItemToBag.added.map(\.productId) == [pid(1)])
        #expect(addItemToBag.added.map(\.quantity) == [1])
    }

    @Test("Tapping tells the shopper it is in the bag, with somewhere to go and see it")
    func tappingShowsASnackbarThatOpensTheBag() {
        let navigation = SpyProductActionsNavigation()
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(navigation: navigation, snackbarPresenter: snackbarPresenter)

        viewModel.didTap()

        #expect(snackbarPresenter.shown.first?.title == "In the Bag")
        snackbarPresenter.shown.first?.action?.handler()
        #expect(navigation.switchedToBagTab)
    }

    @Test("A bag button can never put in something the shop cannot supply")
    func neverAddsWhatCannotBeSupplied() {
        let addItemToBag = SpyAddItemToBag()
        let snackbarPresenter = SpySnackbarPresenter()
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
