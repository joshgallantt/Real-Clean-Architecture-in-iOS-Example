import MoneyTestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import SettingsTestSupport
import Testing
import Tracking
import TrackingTestSupport
import Bag
import Money
import Product
@testable import BagUI
@testable import BagUITestSupport

@MainActor
@Suite("What the bag screen delegates, and to what")
struct BagScreenViewModelTests {
    private let navigation = SpyBagNavigation()
    private let setBagItem = SpySetBagItemUseCase()

    /// A screen over a kept bag and a shop that describes exactly these products. A line the shop
    /// does not describe was not asked about, so it stays as it was kept.
    private func makeViewModel(_ items: [BagItem], shopSays products: [Product]) -> (BagScreenViewModel, SpyCheckBagUseCase) {
        let kept = Bag(items: items)
        let checkBag = SpyCheckBagUseCase(answer: kept.checked(against: products, asked: Set(products.map(\.id))))
        let viewModel = BagScreenViewModel(
            navigation: navigation,
            observeBag: StubObserveBagUseCase(kept),
            setBagItem: setBagItem,
            checkBag: checkBag,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
        return (viewModel, checkBag)
    }

    @Test("Rows render from the bag as soon as it appears, before the shop answers about any of it")
    func rendersFromTheBagFirst() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99)], shopSays: [])

        await viewModel.onAppear()

        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.total == usd(9.99))
    }

    @Test("Appearing asks for the bag to be checked, once")
    func appearingChecksTheBag() async {
        let (viewModel, checkBag) = makeViewModel([bagItem(1, price: 9.99), bagItem(2, price: 5)], shopSays: [])

        await viewModel.onAppear()

        #expect(checkBag.callCount == 1)
    }

    @Test("What is drawn and what is listed are both what the check answered")
    func drawsWhatTheCheckAnswered() async {
        let (viewModel, _) = makeViewModel(
            [bagItem(1, quantity: 2, price: 9.99)],
            shopSays: [.fixture(id: 1, price: 12)]
        )

        await viewModel.onAppear()

        #expect(viewModel.rows.map(\.lineTotal) == [usd(24)])
        #expect(viewModel.changes.map(\.id) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12))])
    }

    @Test("Changing how many delegates to the use case with that product and the new quantity")
    func changingQuantityDelegates() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99), bagItem(9, price: 5)], shopSays: [])
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)

        #expect(setBagItem.calls.map(\.productId) == [pid(1)])
        #expect(setBagItem.calls.map(\.quantity) == [3])
    }

    @Test("Changing how many sets the line at the price it is drawn at, not the one it was kept at")
    func changingQuantityKeepsTheShownPrice() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99)], shopSays: [.fixture(id: 1, price: 12)])
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)

        #expect(setBagItem.calls.map(\.lastKnownPrice) == [usd(12)])
    }

    @Test("Swiping to delete sets that product's quantity to zero, not just any product's")
    func swipeToDeleteTargetsTheRightProduct() async {
        let (viewModel, _) = makeViewModel([bagItem(2, price: 9.99), bagItem(9, price: 5)], shopSays: [])
        await viewModel.onAppear()

        viewModel.didSwipeToDelete(productId: pid(2), in: inTheBag)

        #expect(setBagItem.calls.map(\.productId) == [pid(2)])
        #expect(setBagItem.calls.map(\.quantity) == [0])
    }

    @Test("Emptying the bag sets every line's quantity to zero, and no other product's")
    func removingEverythingClearsEveryLine() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99), bagItem(2, price: 5)], shopSays: [])
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)

        #expect(Set(setBagItem.calls.map(\.productId)) == Set([pid(1), pid(2)]))
        #expect(setBagItem.calls.allSatisfy { $0.quantity == 0 })
    }

    @Test("Emptying an already-empty bag asks the use case for nothing")
    func removingEverythingFromAnEmptyBagDoesNothing() async {
        let (viewModel, _) = makeViewModel([], shopSays: [])
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)

        #expect(setBagItem.calls.isEmpty)
    }

    @Test("Leaving sets each line the shop changed as it was drawn, and none of each that went")
    func leavingSetsWhatChanged() async {
        let (viewModel, _) = makeViewModel(
            [
                bagItem(1, quantity: 5, price: 9.99, addedAt: Date(timeIntervalSince1970: 3)),
                bagItem(2, price: 5, addedAt: Date(timeIntervalSince1970: 2)),
                bagItem(3, price: 1, addedAt: Date(timeIntervalSince1970: 1))
            ],
            shopSays: [
                .fixture(id: 1, price: 12, availability: .inStock(remaining: 2)),
                .fixture(id: 2, availability: .outOfStock),
                .fixture(id: 3, price: 1)
            ]
        )
        await viewModel.onAppear()

        viewModel.didDisappear()

        #expect(setBagItem.calls.map(\.productId) == [pid(2), pid(1)])
        #expect(setBagItem.calls.map(\.quantity) == [0, 2])
        #expect(setBagItem.calls.map(\.lastKnownPrice) == [usd(5), usd(12)])
    }

    @Test("Leaving a bag the shop changed nothing about sets nothing")
    func leavingAnUnchangedBagSetsNothing() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99)], shopSays: [.fixture(id: 1, price: 9.99)])
        await viewModel.onAppear()

        viewModel.didDisappear()

        #expect(setBagItem.calls.isEmpty)
    }

    @Test("Leaving before the shop has answered sets nothing")
    func leavingBeforeTheAnswerSetsNothing() async {
        let (viewModel, _) = makeViewModel([bagItem(1, price: 9.99)], shopSays: [.fixture(id: 1, price: 12)])

        viewModel.didDisappear()

        #expect(setBagItem.calls.isEmpty)
    }

    @Test("Tapping a line opens that product, and no other")
    func tappingARowOpensThatProduct() async {
        let (viewModel, _) = makeViewModel(
            [bagItem(3, price: 9.99), bagItem(4, price: 4.99)],
            shopSays: [.fixture(id: 3), .fixture(id: 4, price: 4.99)]
        )
        await viewModel.onAppear()

        viewModel.didTapRow(BagRow(item: bagItem(3, price: 9.99), product: nil), in: inTheBag)

        #expect(navigation.openedProducts == [.fixture(id: 3)])
    }

    @Test("Tapping a line the shop has not answered about yet opens nothing")
    /// The product is what gets opened, so a line the screen cannot name is a line with no page
    /// behind it. It draws as a picture-less row until the answer lands, and then it opens.
    func tappingARowTheShopHasNotAnsweredAboutOpensNothing() async {
        let (viewModel, _) = makeViewModel([bagItem(3, price: 9.99)], shopSays: [])
        await viewModel.onAppear()

        viewModel.didTapRow(BagRow(item: bagItem(3, price: 9.99), product: nil), in: inTheBag)

        #expect(navigation.openedProducts.isEmpty)
    }

    @Test("Tapping something that changed opens that product")
    func tappingAChangeOpensThatProduct() async throws {
        let (viewModel, _) = makeViewModel(
            [bagItem(3, price: 9.99), bagItem(4, price: 4.99)],
            shopSays: [.fixture(id: 3, availability: .outOfStock), .fixture(id: 4, price: 4.99)]
        )
        await viewModel.onAppear()

        viewModel.didTapRow(try #require(viewModel.changes.first), in: inTheBag)

        #expect(navigation.openedProducts == [.fixture(id: 3, availability: .outOfStock)])
    }
}

/// Where the bag's own buttons are drawn. A test about what a tap does to the bag has no reason to
/// say more than that.
private let inTheBag = TrackingContext.screen("bag")
