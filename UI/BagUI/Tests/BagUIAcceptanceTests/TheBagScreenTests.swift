import Foundation
import Testing
import Bag
import Money
import Product
@testable import BagUI

@MainActor
@Suite("Asking the shop what has changed", .serialized)
/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: what the use case sequences, and
/// what it keeps.
struct BagScreenViewModelTests {
    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            observeBag: shop.observeBag,
            observeBagChanges: shop.observeBagChanges,
            lookUpProducts: shop.lookUpProducts,
            setBagItemQuantity: shop.setBagItemQuantity,
            bringBagUpToDate: shop.bringUpToDate,
            acknowledgeBagChange: shop.acknowledge,
            snackbar: shop.snackbar
        )
    }

    private func makeShop(
        items: [BagItem] = [bagItem(1, price: 9.99)],
        catalog: [Product] = [.fixture(id: 1)]
    ) -> FakeShop {
        FakeShop(bag: Bag(items: items), catalog: catalog)
    }

    @Test("Opening the bag asks the shop about everything in it")
    func opening() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.lookups == [[pid(1)]])
    }

    @Test("Opening it again asks again — coming back after a while is the whole point")
    func openingAgain() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.onAppear()
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.lookups == [[pid(1)], [pid(1)]])
    }

    @Test("A price that moved between visits is caught, applied and shown")
    func priceMovedBetweenVisits() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        shop.catalog = [.fixture(id: 1, price: 12.99)]
        viewModel.onAppear()
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentChanges.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(viewModel.priceChangedRows.map(\.id) == [pid(1)])
        #expect(viewModel.removedRows.isEmpty)
        #expect(viewModel.total == usd(12.99))
    }

    @Test("Catching up does not itself count as a change, or the screen would ask forever")
    func catchingUpDoesNotLoop() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        shop.catalog = [.fixture(id: 1, price: 12.99)]
        viewModel.onAppear()
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.lookups.count == 2)
    }

    @Test("Something out of stock leaves the bag and is listed as removed")
    func outOfStockIsRemoved() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.removedRows.map(\.id) == [pid(1)])
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Availability is a yes-or-no to a bag, whatever the count happens to be")
    func stockIsAYesOrNo() async {
        let plenty = makeShop(catalog: [.fixture(id: 1, availability: .inStock(remaining: 1))])
        let plentyScreen = makeViewModel(shop: plenty)
        let none = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let noneScreen = makeViewModel(shop: none)

        plentyScreen.onAppear()
        noneScreen.onAppear()
        await settle(plenty)
        await settle(none)

        #expect(plenty.currentChanges.isEmpty)
        #expect(none.currentChanges.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("Changing how many asks again")
    func changingQuantityAsks() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3)
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.lookups.count == 2)
        #expect(shop.currentBag.quantity(of: pid(1)) == 3)
    }

    @Test("Taking something out asks again")
    func removingAsks() async {
        let shop = makeShop(
            items: [
                bagItem(1, price: 9.99, addedAt: .distantPast),
                bagItem(2, price: 5, addedAt: .now)
            ],
            catalog: [.fixture(id: 1), .fixture(id: 2)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didSwipeToDelete(productId: pid(2))
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentBag.items.map(\.id) == [pid(1)])
        #expect(shop.lookups.count == 2)
    }

    @Test("Saying a change has been seen clears it without going back to the shop")
    func acknowledgingDoesNotAsk() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        let asksSoFar = shop.lookups.count
        #expect(viewModel.priceChangedRows.count == 1)

        viewModel.didAcknowledgeChange(productId: pid(1))
        await settle(shop)

        #expect(shop.lookups.count == asksSoFar)
        #expect(viewModel.priceChangedRows.isEmpty)
    }

    @Test("Asking to be notified clears the row and says so")
    func notifyMe() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        #expect(viewModel.removedRows.count == 1)

        viewModel.didAskToBeNotified(productId: pid(1))
        await settle(shop)

        #expect(viewModel.removedRows.isEmpty)
        #expect(shop.shownSnackbars.map(\.title) == ["We'll Let You Know"])
    }

    @Test("A shop that answers with nothing leaves the bag exactly as it was")
    func catalogSilenceIsHarmless() async {
        let shop = makeShop(catalog: [])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentChanges.isEmpty)
        #expect(shop.currentBag.items.map(\.id) == [pid(1)])
        #expect(viewModel.total == usd(9.99))
    }

    @Test("Rows render from the bag before the shop answers, and the total never waits")
    func rowsDoNotWaitForTheCatalog() {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()

        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.rows.first?.name == nil)
        #expect(viewModel.total == usd(9.99))
    }

    @Test("Names and pictures arrive once the shop answers")
    func namesArriveLater() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.rows.first?.name == "Product 1")
    }
}

@MainActor
private func settle(_ shop: FakeShop, untilAskedTimes times: Int = 1) async {
    for _ in 0..<200 where shop.lookups.count < times {
        await Task.yield()
    }
    for _ in 0..<20 {
        await Task.yield()
    }
}

