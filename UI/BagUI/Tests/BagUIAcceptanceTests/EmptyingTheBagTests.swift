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
@testable import BagUITestSupport
@testable import BagUI

@MainActor
@Suite("Emptying the bag", .serialized)
struct EmptyingTheBagTests {
    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            navigation: SpyBagNavigation(),
            observeBag: shop.observeBag,
            setBagItem: shop.setBagItem,
            checkBag: shop.checkBag,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    @Test("A shopper empties their whole bag and it is empty, and worth nothing at all")
    func removesEverything() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1), .fixture(id: 2, price: 5)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)
        await viewModel.inFlight?.value

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
        #expect(viewModel.total == nil)
    }

    @Test("Emptying a bag the shop had changed leaves nothing kept once the shopper has left")
    func removesEverythingFromAChangedBag() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)
        await viewModel.inFlight?.value
        viewModel.didDisappear()

        #expect(viewModel.isEmpty)
        #expect(shop.currentBag.isEmpty)
    }

    @Test("Emptying a bag that is already empty asks nothing of anybody")
    func removingEverythingFromNothing() async {
        let shop = FakeShop(bag: Bag(), catalog: [])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didRemoveEverything(in: inTheBag)
        await viewModel.inFlight?.value

        #expect(shop.currentBag.isEmpty)
        #expect(shop.lookups.isEmpty)
    }
}

/// Where the bag's own buttons are drawn. A test about what a tap does to the bag has no reason to
/// say more than that.
private let inTheBag = TrackingContext.screen("bag")
