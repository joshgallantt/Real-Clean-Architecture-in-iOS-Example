import MoneyTestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import Testing
import Bag
import Money
import Product
@testable import BagUITestSupport
@testable import BagUI

@MainActor
@Suite("Dealing with a whole section at once", .serialized)
/// A shopper who has been away a while comes back to a screenful of notices. Clearing them one tap
/// at a time is the same work the shop made for them; each section can be accepted in one go.
struct DealingWithAWholeSectionTests {
    private let navigation = SpyBagNavigation()

    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            navigation: navigation,
            observeBag: shop.observeBag,
            observeNotices: shop.observeNotices,
            setBagItemQuantity: shop.setBagItemQuantity,
            bringBagUpToDate: shop.bringUpToDate,
            acknowledgeNotices: shop.acknowledge
        )
    }

    @Test("Accepting everything that has gone clears the whole section in one tap")
    func acceptsAllRemoved() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [
                .fixture(id: 1, availability: .outOfStock),
                .fixture(id: 2, availability: .outOfStock)
            ]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        #expect(viewModel.notices(in: .outOfStock).count == 2)

        viewModel.didAcceptAll(.outOfStock)

        #expect(viewModel.notices(in: .outOfStock).isEmpty)
    }

    @Test("Accepting every price move leaves the bag itself alone, at the new prices")
    func acceptsAllPriceChanges() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 7)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        #expect(viewModel.notices(in: .priceWentUp).count == 2)

        viewModel.didAcceptAll(.priceWentUp)

        #expect(viewModel.notices(in: .priceWentUp).isEmpty)
        #expect(viewModel.rows.count == 2)
        #expect(viewModel.total == usd(19.99))
    }

    @Test("Accepting one section leaves the others still waiting")
    func acceptingOneSectionLeavesTheRest() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [
                .fixture(id: 1, price: 12.99),
                .fixture(id: 2, availability: .outOfStock)
            ]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didAcceptAll(.priceWentUp)

        #expect(viewModel.notices(in: .priceWentUp).isEmpty)
        #expect(viewModel.notices(in: .outOfStock).map(\.id) == [pid(2)])
    }

    @Test("A shopper empties their whole bag and it is empty, and worth nothing at all")
    func removesEverything() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1), .fixture(id: 2)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didRemoveEverything()
        await viewModel.inFlight?.value

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
        #expect(viewModel.total == nil)
    }

    @Test("Emptying a bag that is already empty asks nothing of anybody")
    func removingEverythingFromNothing() async {
        let shop = FakeShop(bag: Bag(), catalog: [])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didRemoveEverything()

        #expect(shop.currentBag.isEmpty)
    }
}
