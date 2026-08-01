import Foundation
import Testing
import Bag
import Money
import Product
@testable import BagUI

@MainActor
@Suite("What the bag screen delegates, and to what")
struct BagScreenViewModelTests {
    private func makeViewModel(
        navigation: SpyNavigation = SpyNavigation(),
        observeBag: StubObserveBag = StubObserveBag(),
        observeNotices: StubObserveNotices = StubObserveNotices(),
        setBagItemQuantity: SpySetBagItemQuantity = SpySetBagItemQuantity(),
        bringBagUpToDate: StubBringBagUpToDate = StubBringBagUpToDate(),
        acknowledgeNotices: SpyAcknowledgeNotices = SpyAcknowledgeNotices()
    ) -> BagScreenViewModel {
        BagScreenViewModel(
            navigation: navigation,
            observeBag: observeBag,
            observeNotices: observeNotices,
            setBagItemQuantity: setBagItemQuantity,
            bringBagUpToDate: bringBagUpToDate,
            acknowledgeNotices: acknowledgeNotices
        )
    }

    @Test("Rows render from the bag as soon as it appears, before the shop answers about any of it")
    func rendersFromTheBagFirst() {
        let observeBag = StubObserveBag(Bag(items: [bagItem(1, price: 9.99)]))
        let viewModel = makeViewModel(observeBag: observeBag)

        viewModel.onAppear()

        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.total == usd(9.99))
    }

    @Test("Changing how many delegates to the use case with that product and the new quantity")
    func changingQuantityDelegates() async {
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(setBagItemQuantity: setBagItemQuantity)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3)

        #expect(setBagItemQuantity.calls.map(\.productId) == [pid(1)])
        #expect(setBagItemQuantity.calls.map(\.quantity) == [3])
    }

    @Test("Swiping to delete sets that product's quantity to zero, not just any product's")
    func swipeToDeleteTargetsTheRightProduct() {
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(setBagItemQuantity: setBagItemQuantity)

        viewModel.didSwipeToDelete(productId: pid(2))

        #expect(setBagItemQuantity.calls.map(\.productId) == [pid(2)])
        #expect(setBagItemQuantity.calls.map(\.quantity) == [0])
    }

    @Test("Removing a repriced line sets that one product's quantity to zero")
    func removingAChangedItemTargetsTheRightProduct() {
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(setBagItemQuantity: setBagItemQuantity)

        viewModel.didRemoveChangedItem(productId: pid(4))

        #expect(setBagItemQuantity.calls.map(\.productId) == [pid(4)])
        #expect(setBagItemQuantity.calls.map(\.quantity) == [0])
    }

    @Test("Emptying the bag sets every line's quantity to zero, and no other product's")
    func removingEverythingClearsEveryLine() {
        let observeBag = StubObserveBag(Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]))
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItemQuantity: setBagItemQuantity)
        viewModel.onAppear()

        viewModel.didRemoveEverything()

        #expect(Set(setBagItemQuantity.calls.map(\.productId)) == Set([pid(1), pid(2)]))
        #expect(setBagItemQuantity.calls.allSatisfy { $0.quantity == 0 })
    }

    @Test("Emptying an already-empty bag asks the use case for nothing")
    func removingEverythingFromAnEmptyBagDoesNothing() {
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(setBagItemQuantity: setBagItemQuantity)
        viewModel.onAppear()

        viewModel.didRemoveEverything()

        #expect(setBagItemQuantity.calls.isEmpty)
    }

    @Test("Tapping a line opens that product, and no other")
    func tappingARowOpensThatProduct() {
        let navigation = SpyNavigation()
        let viewModel = makeViewModel(navigation: navigation)

        viewModel.didTapRow(productId: pid(3))

        #expect(navigation.openedProducts == [pid(3)])
    }

    @Test("Accepting a section acknowledges every product it is showing, and none of another section's")
    func acceptingASectionAcknowledgesItsOwnProducts() {
        let observeNotices = StubObserveNotices(Notices([
            .outOfStock(productId: pid(1)),
            .priceWentUp(productId: pid(2), from: usd(5), to: usd(7))
        ]))
        let acknowledgeNotices = SpyAcknowledgeNotices()
        let viewModel = makeViewModel(observeNotices: observeNotices, acknowledgeNotices: acknowledgeNotices)
        viewModel.onAppear()

        viewModel.didAcceptAll(.outOfStock)

        #expect(acknowledgeNotices.acknowledged == [pid(1)])
    }

    @Test("Accepting a section nothing is showing acknowledges nothing")
    func acceptingAnEmptySectionAcknowledgesNothing() {
        let acknowledgeNotices = SpyAcknowledgeNotices()
        let viewModel = makeViewModel(acknowledgeNotices: acknowledgeNotices)
        viewModel.onAppear()

        viewModel.didAcceptAll(.outOfStock)

        #expect(acknowledgeNotices.acknowledged.isEmpty)
    }

    @Test("What the shop is told to catch up on is what the screen appeared showing")
    func asksTheShopWhatIsOnScreen() async {
        let observeBag = StubObserveBag(Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]))
        let bringBagUpToDate = StubBringBagUpToDate()
        let viewModel = makeViewModel(observeBag: observeBag, bringBagUpToDate: bringBagUpToDate)

        viewModel.onAppear()
        await yieldUntil { bringBagUpToDate.callCount > 0 }
        await settle()

        #expect(bringBagUpToDate.callCount == 1)
    }
}
