import MoneyTestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import Settings
import SettingsTestSupport
import Testing
import TrackingTestSupport
import Bag
import Money
import Product
@testable import BagUITestSupport
@testable import BagUI

@MainActor
@Suite("Hiding what changed", .serialized)
/// A shopper can switch the changes section off in Settings. The bag underneath it is the same bag
/// either way — the setting hides the telling, never the truth.
struct HidingWhatChangedTests {
    private let settings: StubObserveSettingUseCase
    private let shop: FakeShop
    private let viewModel: BagScreenViewModel

    init() {
        let settings = StubObserveSettingUseCase(turnedOff: [.bagChangesSection])
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, availability: .outOfStock)]
        )
        self.settings = settings
        self.shop = shop
        self.viewModel = BagScreenViewModel(
            navigation: SpyBagNavigation(),
            observeBag: shop.observeBag,
            setBagItem: shop.setBagItem,
            checkBag: shop.checkBag,
            observeSetting: settings,
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    @Test("With the section switched off nothing is listed, and the lines are still the truth")
    func switchedOff() async {
        await viewModel.onAppear()

        #expect(viewModel.hasChanges == false)
        #expect(viewModel.changes.isEmpty)
        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.total == usd(12.99))
    }

    @Test("Switching it back on shows what changed, without leaving the bag")
    func switchedBackOn() async {
        await viewModel.onAppear()

        settings.turn(.bagChangesSection, on: true)

        #expect(Set(viewModel.changes.map(\.id)) == [
            .priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99)),
            .soldOut(productId: pid(2))
        ])
    }

    @Test("Switching it off hides a list that was showing")
    func switchedOffWhileShowing() async {
        settings.turn(.bagChangesSection, on: true)
        await viewModel.onAppear()
        #expect(viewModel.hasChanges)

        settings.turn(.bagChangesSection, on: false)

        #expect(viewModel.hasChanges == false)
    }

    @Test("A hidden section still counts as seen once the shopper leaves")
    func leavingStillKeepsTheBagAsSeen() async {
        await viewModel.onAppear()

        viewModel.didDisappear()
        settings.turn(.bagChangesSection, on: true)
        await viewModel.onAppear()

        #expect(shop.currentBag.items.map(\.id) == [pid(1)])
        #expect(shop.currentBag.total == usd(12.99))
        #expect(viewModel.hasChanges == false)
    }

    @Test("Another setting being off does not hide it")
    func anotherSettingDoesNotHideIt() async {
        settings.turn(.bagChangesSection, on: true)
        settings.turn(.favoritesStockAlertsSection, on: false)

        await viewModel.onAppear()

        #expect(viewModel.hasChanges)
    }
}
