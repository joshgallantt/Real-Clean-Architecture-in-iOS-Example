import BagTestSupport
import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Tracking
import TrackingTestSupport
import Bag
import Money
import Product
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Suite("The bag button")
struct BagButtonViewModelTests {
    private func makeViewModel(
        product: Product = .fixture(id: 1),
        observeBag: StubObserveBagUseCase = StubObserveBagUseCase(Bag(items: [])),
        setBagItem: SpySetBagItemUseCase = SpySetBagItemUseCase(),
        navigation: SpyProductActionsNavigation = SpyProductActionsNavigation(),
        snackbarPresenter: SpySnackbarPresenting = SpySnackbarPresenting()
    ) -> BagButtonViewModel {
        let viewModel = BagButtonViewModel(
            product: product,
            observeBag: observeBag,
            setBagItem: setBagItem,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter,
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
        /// The screen subscribes on appear rather than in `init`, so the test has
        /// to do what the screen does before it can expect anything published.
        viewModel.onAppear()
        return viewModel
    }

    @Test("The count shown is how many of this product the bag holds, whatever else is in it")
    func quantityFollowsTheBag() {
        let bag = Bag(items: [
            BagItem(productId: pid(1), quantity: 3, lastKnownPrice: Money(amount: 5, currency: .usd), dateAdded: .distantPast),
            BagItem(productId: pid(2), quantity: 7, lastKnownPrice: Money(amount: 5, currency: .usd), dateAdded: .distantPast)
        ])
        let viewModel = makeViewModel(observeBag: StubObserveBagUseCase(bag))

        #expect(viewModel.quantity == 3)
    }

    @Test("Tapping adds exactly one of the product, at its price, to the bag")
    func tappingAddsOneAtItsPrice() {
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(product: .fixture(id: 1), setBagItem: setBagItem)

        viewModel.didTap(in: .screen("product_details"))

        #expect(setBagItem.calls.map(\.productId) == [pid(1)])
        #expect(setBagItem.calls.map(\.quantity) == [1])
    }

    @Test("Tapping tells the shopper it is in the bag, with somewhere to go and see it")
    func tappingShowsASnackbarThatOpensTheBag() {
        let navigation = SpyProductActionsNavigation()
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(navigation: navigation, snackbarPresenter: snackbarPresenter)

        viewModel.didTap(in: .screen("product_details"))

        #expect(snackbarPresenter.shown.first?.title == "In the Bag")
        snackbarPresenter.shown.first?.action?.handler()
        #expect(navigation.switchedToBagTab)
    }

    @Test("A bag button can never put in something the shop cannot supply")
    func neverAddsWhatCannotBeSupplied() {
        let setBagItem = SpySetBagItemUseCase()
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(
            product: .fixture(id: 1, availability: .outOfStock),
            setBagItem: setBagItem,
            snackbarPresenter: snackbarPresenter
        )

        viewModel.didTap(in: .screen("product_details"))

        #expect(setBagItem.calls.isEmpty)
        #expect(snackbarPresenter.shown.isEmpty)
    }
}
