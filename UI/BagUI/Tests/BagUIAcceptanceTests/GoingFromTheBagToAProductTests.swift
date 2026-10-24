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
@Suite("Going from the bag to a product", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: a shopper taps a line and
/// expects the thing. These went untested while opening a product was called straight out of the
/// view — there was a `SpyBagNavigation` and nothing that could assert on it.
struct GoingFromTheBagToAProductTests {
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

    @Test("Tapping a line in the bag opens that product")
    func tappingABagLine() async {
        let shop = FakeShop(bag: Bag(items: [bagItem(1, price: 9.99)]), catalog: [.fixture(id: 1)])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts.map(\.id) == [pid(1)])
    }

    @Test("Tapping something that sold out opens it — it is coming back, and the page is where you wait")
    func tappingAnOutOfStockNotice() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99)]),
            catalog: [.fixture(id: 1, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts.map(\.id) == [pid(1)])
    }

    @Test("Tapping something repriced opens it, because that is where the decision gets made")
    func tappingAPriceNotice() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99)]),
            catalog: [.fixture(id: 1, price: 12.99)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts.map(\.id) == [pid(1)])
    }

}
