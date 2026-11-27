import MoneyTestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import Testing
import Tracking
import TrackingUI
import TrackingTestSupport
import Bag
import Money
import Product
@testable import BagUI
@testable import BagUITestSupport

@MainActor
@Suite("What the bag screen delegates, and to what")
struct BagScreenViewModelTests {
    private func makeViewModel(
        navigation: SpyBagNavigation = SpyBagNavigation(),
        observeBag: StubObserveBagUseCase = StubObserveBagUseCase(),
        observeNotices: StubObserveNoticesUseCase = StubObserveNoticesUseCase(),
        setBagItem: SpySetBagItemUseCase = SpySetBagItemUseCase(),
        refreshBag: SpyRefreshBagUseCase = SpyRefreshBagUseCase(),
        acknowledgeNotices: SpyAcknowledgeNoticesUseCase = SpyAcknowledgeNoticesUseCase()
    ) -> BagScreenViewModel {
        BagScreenViewModel(
            navigation: navigation,
            observeBag: observeBag,
            observeNotices: observeNotices,
            setBagItem: setBagItem,
            refreshBag: refreshBag,
            acknowledgeNotices: acknowledgeNotices,
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    @Test("Rows render from the bag as soon as it appears, before the shop answers about any of it")
    func rendersFromTheBagFirst() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(1, price: 9.99)]))
        let viewModel = makeViewModel(observeBag: observeBag)

        await viewModel.onAppear()

        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.total == usd(9.99))
    }

    @Test("Changing how many delegates to the use case with that product and the new quantity")
    func changingQuantityDelegates() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(1, price: 9.99), bagItem(9, price: 5)]))
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItem: setBagItem)
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)

        #expect(setBagItem.calls.map(\.productId) == [pid(1)])
        #expect(setBagItem.calls.map(\.quantity) == [3])
    }

    @Test("Swiping to delete sets that product's quantity to zero, not just any product's")
    func swipeToDeleteTargetsTheRightProduct() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(2, price: 9.99), bagItem(9, price: 5)]))
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItem: setBagItem)
        await viewModel.onAppear()

        viewModel.didSwipeToDelete(productId: pid(2), in: inTheBag)

        #expect(setBagItem.calls.map(\.productId) == [pid(2)])
        #expect(setBagItem.calls.map(\.quantity) == [0])
    }

    @Test("Removing a repriced line sets that one product's quantity to zero")
    func removingAChangedItemTargetsTheRightProduct() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(4, price: 9.99), bagItem(9, price: 5)]))
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItem: setBagItem)
        await viewModel.onAppear()

        viewModel.didRemoveChangedItem(productId: pid(4), in: inTheBag)

        #expect(setBagItem.calls.map(\.productId) == [pid(4)])
        #expect(setBagItem.calls.map(\.quantity) == [0])
    }

    @Test("Emptying the bag sets every line's quantity to zero, and no other product's")
    func removingEverythingClearsEveryLine() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]))
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItem: setBagItem)
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)

        #expect(Set(setBagItem.calls.map(\.productId)) == Set([pid(1), pid(2)]))
        #expect(setBagItem.calls.allSatisfy { $0.quantity == 0 })
    }

    @Test("Emptying an already-empty bag asks the use case for nothing")
    func removingEverythingFromAnEmptyBagDoesNothing() async {
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(setBagItem: setBagItem)
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)

        #expect(setBagItem.calls.isEmpty)
    }

    @Test("Tapping a line opens that product, and no other")
    func tappingARowOpensThatProduct() async {
        let navigation = SpyBagNavigation()
        let refreshBag = SpyRefreshBagUseCase()
        refreshBag.products = [.fixture(id: 3), .fixture(id: 4)]
        let viewModel = makeViewModel(
            navigation: navigation,
            observeBag: StubObserveBagUseCase(Bag(items: [bagItem(3, price: 9.99), bagItem(4, price: 4.99)])),
            refreshBag: refreshBag
        )
        await viewModel.onAppear()

        viewModel.didTapRow(BagRow(item: bagItem(3, price: 9.99), product: nil), in: inTheBag)

        #expect(navigation.openedProducts == [.fixture(id: 3)])
    }

    @Test("Tapping a line the shop has not answered about yet opens nothing")
    /// The product is what gets opened, so a line the screen cannot name is a line with no page
    /// behind it. It draws as a picture-less row until the answer lands, and then it opens.
    func tappingARowTheShopHasNotAnsweredAboutOpensNothing() async {
        let navigation = SpyBagNavigation()
        let viewModel = makeViewModel(
            navigation: navigation,
            observeBag: StubObserveBagUseCase(Bag(items: [bagItem(3, price: 9.99)]))
        )
        await viewModel.onAppear()

        viewModel.didTapRow(BagRow(item: bagItem(3, price: 9.99), product: nil), in: inTheBag)

        #expect(navigation.openedProducts.isEmpty)
    }

    @Test("Accepting a section acknowledges every product it is showing, and none of another section's")
    func acceptingASectionAcknowledgesItsOwnProducts() async {
        let observeNotices = StubObserveNoticesUseCase(Notices([
            .outOfStock(productId: pid(1)),
            .priceWentUp(productId: pid(2), from: usd(5), to: usd(7))
        ]))
        let acknowledgeNotices = SpyAcknowledgeNoticesUseCase()
        let viewModel = makeViewModel(observeNotices: observeNotices, acknowledgeNotices: acknowledgeNotices)
        await viewModel.onAppear()

        viewModel.didAcceptAll(.outOfStock, in: inTheBag)

        #expect(acknowledgeNotices.acknowledged == [pid(1)])
    }

    @Test("Accepting a section nothing is showing acknowledges nothing")
    func acceptingAnEmptySectionAcknowledgesNothing() async {
        let acknowledgeNotices = SpyAcknowledgeNoticesUseCase()
        let viewModel = makeViewModel(acknowledgeNotices: acknowledgeNotices)
        await viewModel.onAppear()

        viewModel.didAcceptAll(.outOfStock, in: inTheBag)

        #expect(acknowledgeNotices.acknowledged.isEmpty)
    }

    @Test("What the shop is told to catch up on is what the screen appeared showing")
    func asksTheShopWhatIsOnScreen() async {
        let observeBag = StubObserveBagUseCase(Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]))
        let refreshBag = SpyRefreshBagUseCase()
        let viewModel = makeViewModel(observeBag: observeBag, refreshBag: refreshBag)

        await viewModel.onAppear()

        #expect(refreshBag.callCount == 1)
    }
}

/// Where the bag's own buttons are drawn. A test about what a tap does to the bag has no reason to
/// say more than that.
private let inTheBag = TrackingContext.screen("bag")
