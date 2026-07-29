import Foundation
import Testing
import Bag
import Product
@testable import BagUI

/// When the bag screen asks the shop what has changed, and — just as importantly — when
/// it does not. The tab is created once and held alive for the whole session, so nothing
/// else will ever ask on the shopper's behalf.
@MainActor
/// Serialised: every test here runs on the main actor and makes progress by yielding to
/// the screen's lookup task. Run in parallel they compete for the same actor, and a test
/// can run out of yields because another one was holding it.
@Suite("Asking the shop what has changed", .serialized)
struct BagScreenViewModelTests {

    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            observeBag: shop.observeBag,
            observeBagChanges: shop.observeBagChanges,
            getProductsByIds: shop.getProductsByIds,
            setBagItemQuantity: shop.setBagItemQuantity,
            reconcileBag: shop.reconcile,
            acknowledgeBagChange: shop.acknowledge,
            snackbar: shop.snackbar
        )
    }

    private func makeShop(
        items: [BagItem] = [BagItem(id: 1, lastKnownPrice: 9.99)],
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

        #expect(shop.lookups == [[1]])
    }

    @Test("Opening it again asks again — coming back after a while is the whole point")
    func openingAgain() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.onAppear()
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.lookups == [[1], [1]])
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

        #expect(shop.currentChanges.priceChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(viewModel.priceChangedRows.map(\.id) == [1])
        #expect(viewModel.removedRows.isEmpty)
        #expect(viewModel.total.cents == 1299)
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

        // Two visits, two lookups. The repricing that came back from the second one
        // saved a new bag, which must not send the screen round again.
        #expect(shop.lookups.count == 2)
    }

    @Test("Something out of stock leaves the bag and is listed as removed")
    func outOfStockIsRemoved() async {
        let shop = makeShop(catalog: [.fixture(id: 1, stock: 0)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.removedRows.map(\.id) == [1])
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Stock is a yes-or-no to a bag, whatever the count happens to be")
    func stockIsAYesOrNo() async {
        let plenty = makeShop(catalog: [.fixture(id: 1, stock: 1)])
        let plentyScreen = makeViewModel(shop: plenty)
        let none = makeShop(catalog: [.fixture(id: 1, stock: 0)])
        let noneScreen = makeViewModel(shop: none)

        plentyScreen.onAppear()
        noneScreen.onAppear()
        await settle(plenty)
        await settle(none)

        #expect(plenty.currentChanges.isEmpty)
        #expect(none.currentChanges.removals == [.outOfStock(itemId: 1)])
    }

    @Test("Changing how many asks again")
    func changingQuantityAsks() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didChangeQuantity(itemId: 1, quantity: 3)
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.lookups.count == 2)
        #expect(shop.currentBag.quantity(forItemId: 1) == 3)
    }

    @Test("Taking something out asks again")
    func removingAsks() async {
        let shop = makeShop(
            items: [
                BagItem(id: 1, lastKnownPrice: 9.99, dateAdded: .distantPast),
                BagItem(id: 2, lastKnownPrice: 5, dateAdded: .now)
            ],
            catalog: [.fixture(id: 1), .fixture(id: 2)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didSwipeToDelete(itemId: 2)
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentBag.items.map(\.id) == [1])
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

        viewModel.didAcknowledgeChange(itemId: 1)
        await settle(shop)

        #expect(shop.lookups.count == asksSoFar)
        #expect(viewModel.priceChangedRows.isEmpty)
    }

    @Test("Asking to be notified clears the row and says so")
    func notifyMe() async {
        let shop = makeShop(catalog: [.fixture(id: 1, stock: 0)])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        #expect(viewModel.removedRows.count == 1)

        viewModel.didAskToBeNotified(itemId: 1)
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
        #expect(shop.currentBag.items.map(\.id) == [1])
        #expect(viewModel.total.cents == 999)
    }

    @Test("Rows render from the bag before the shop answers, and the total never waits")
    func rowsDoNotWaitForTheCatalog() {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()

        // No settling: the lookup has not come back yet.
        #expect(viewModel.rows.map(\.id) == [1])
        #expect(viewModel.rows.first?.name == nil)
        #expect(viewModel.total.cents == 999)
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

/// Waits for the shop to have been asked, and for the saves that follow to land.
///
/// Polls rather than awaiting the screen's task: the task is main-actor isolated and so
/// is every test here, and awaiting its value from the same actor wedges both. It
/// returns as soon as the count reaches `times`, so the wait is only as long as the work
/// actually takes.
@MainActor
private func settle(_ shop: FakeShop, untilAskedTimes times: Int = 1) async {
    for _ in 0..<200 where shop.lookups.count < times {
        await Task.yield()
    }
    // The lookup's own saves ripple back through two publishers before the screen has
    // rendered them.
    for _ in 0..<20 {
        await Task.yield()
    }
}

private extension Double {
    var cents: Int { Int((self * 100).rounded()) }
}
