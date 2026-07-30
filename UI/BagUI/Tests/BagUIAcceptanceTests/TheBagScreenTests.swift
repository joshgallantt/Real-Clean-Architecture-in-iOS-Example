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
            acknowledgeBagChange: shop.acknowledge
        )
    }

    private func makeShop(
        items: [BagItem] = [bagItem(1, price: 9.99)],
        changes: BagChanges = BagChanges(),
        catalog: [Product] = [.fixture(id: 1)]
    ) -> FakeShop {
        FakeShop(bag: Bag(items: items), changes: changes, catalog: catalog)
    }

    @Test("Something the shop has run out of still shows what it was")
    func outOfStockRowsKeepTheirNames() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.outOfStockRows.first?.name == "Product 1")
        #expect(viewModel.outOfStockRows.first?.imageURL != nil)
    }

    @Test("A notice waiting from a previous visit still says what it is about")
    func noticesFromLastTimeAreNamed() async {
        let shop = makeShop(
            items: [],
            changes: BagChanges([.outOfStock(productId: pid(7))]),
            catalog: [.fixture(id: 7, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.outOfStockRows.map(\.id) == [pid(7)])
        #expect(viewModel.outOfStockRows.first?.name == "Product 7")
    }

    @Test("A price notice about something still in the bag keeps its name too")
    func priceNoticesAreNamed() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 19.99)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.priceIncreaseRows.first?.name == "Product 1")
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
        #expect(viewModel.priceIncreaseRows.map(\.id) == [pid(1)])
        #expect(viewModel.outOfStockRows.isEmpty)
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

    @Test("Something out of stock leaves the bag and is listed as out of stock")
    func outOfStockIsRemoved() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.outOfStockRows.map(\.id) == [pid(1)])
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Something the shop has stopped selling is listed apart, where no bell is offered")
    func discontinuedIsItsOwnSection() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [
                .fixture(id: 1, availability: .outOfStock),
                .fixture(id: 2, availability: .discontinued)
            ]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.outOfStockRows.map(\.id) == [pid(1)])
        #expect(viewModel.discontinuedRows.map(\.id) == [pid(2)])
        #expect(viewModel.isEmpty)
    }

    @Test("A row repeats nothing its section has already said, and speaks up only when it knows more")
    func rowsDoNotRepeatTheirSection() async {
        let shop = makeShop(
            items: [
                bagItem(1, price: 9.99),
                bagItem(2, price: 9.99),
                bagItem(3, quantity: 4, price: 9.99),
                bagItem(4, quantity: 3, price: 9.99),
                bagItem(5, price: 5)
            ],
            catalog: [
                .fixture(id: 1, availability: .outOfStock),
                .fixture(id: 2, availability: .discontinued),
                .fixture(id: 3, availability: .inStock(remaining: 2)),
                .fixture(id: 4, availability: .inStock(remaining: 1)),
                .fixture(id: 5, price: 8)
            ]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.outOfStockRows.first?.detail == nil)
        #expect(viewModel.discontinuedRows.first?.detail == nil)
        #expect(viewModel.priceIncreaseRows.first?.detail == nil)

        // How many are left is the one thing the heading above cannot say.
        #expect(Set(viewModel.shortageRows.compactMap(\.detail)) == ["Only 2 left", "Only 1 left"])
        #expect(viewModel.priceIncreaseRows.first?.priceMove != nil)
        #expect(viewModel.outOfStockRows.first?.priceMove == nil)
    }

    @Test("A price move carries both amounts and which way it went, so the screen can show it")
    func priceMoveCarriesBothAmounts() async {
        let dearer = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let dearerScreen = makeViewModel(shop: dearer)
        let cheaper = makeShop(catalog: [.fixture(id: 1, price: 4.99)])
        let cheaperScreen = makeViewModel(shop: cheaper)

        dearerScreen.onAppear()
        cheaperScreen.onAppear()
        await settle(dearer)
        await settle(cheaper)

        let wentUp = dearerScreen.priceIncreaseRows.first?.priceMove
        #expect(wentUp?.was == usd(9.99).formatted())
        #expect(wentUp?.now == usd(12.99).formatted())
        #expect(wentUp?.isCheaper == false)

        #expect(cheaperScreen.priceDecreaseRows.first?.priceMove?.isCheaper == true)
    }

    @Test("A bag emptied by the shop still shows why, rather than looking like an empty bag")
    func emptiedByTheShopStillExplains() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.isEmpty)
        #expect(viewModel.hasNews)
    }

    @Test("A shopper who will not pay the new price takes it out, and it goes with its notice")
    func removesSomethingThatWentUp() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        #expect(viewModel.priceIncreaseRows.map(\.id) == [pid(1)])

        viewModel.didRemoveChangedItem(productId: pid(1))
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.priceIncreaseRows.isEmpty)
    }

    @Test("A rise and a drop are listed apart, because only one of them asks anything of a shopper")
    func risesAndDropsAreListedApart() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 20)],
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 15)]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.priceIncreaseRows.map(\.id) == [pid(1)])
        #expect(viewModel.priceDecreaseRows.map(\.id) == [pid(2)])
    }

    @Test("Accepting the rises leaves the drops alone")
    func acceptingRisesLeavesDrops() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 20)],
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 15)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didAcceptAll(viewModel.priceIncreaseRows)

        #expect(viewModel.priceIncreaseRows.isEmpty)
        #expect(viewModel.priceDecreaseRows.map(\.id) == [pid(2)])
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
        #expect(none.currentChanges.outOfStock == [.outOfStock(productId: pid(1))])
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
        #expect(viewModel.priceIncreaseRows.count == 1)

        viewModel.didAcknowledgeChange(productId: pid(1))
        await settle(shop)

        #expect(shop.lookups.count == asksSoFar)
        #expect(viewModel.priceIncreaseRows.isEmpty)
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
@Suite("Dealing with a whole section at once", .serialized)
/// A shopper who has been away a while comes back to a screenful of notices. Clearing them one tap
/// at a time is the same work the shop made for them; each section can be accepted in one go.
struct DealingWithAWholeSectionTests {
    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            observeBag: shop.observeBag,
            observeBagChanges: shop.observeBagChanges,
            lookUpProducts: shop.lookUpProducts,
            setBagItemQuantity: shop.setBagItemQuantity,
            bringBagUpToDate: shop.bringUpToDate,
            acknowledgeBagChange: shop.acknowledge
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
        viewModel.onAppear()
        await settle(shop)
        #expect(viewModel.outOfStockRows.count == 2)

        viewModel.didAcceptAll(viewModel.outOfStockRows)

        #expect(viewModel.outOfStockRows.isEmpty)
    }

    @Test("Accepting every price move leaves the bag itself alone, at the new prices")
    func acceptsAllPriceChanges() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 7)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        #expect(viewModel.priceIncreaseRows.count == 2)

        viewModel.didAcceptAll(viewModel.priceIncreaseRows)

        #expect(viewModel.priceIncreaseRows.isEmpty)
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
        viewModel.onAppear()
        await settle(shop)

        viewModel.didAcceptAll(viewModel.priceIncreaseRows)

        #expect(viewModel.priceIncreaseRows.isEmpty)
        #expect(viewModel.outOfStockRows.map(\.id) == [pid(2)])
    }

    @Test("A shopper empties their whole bag and it is empty, and worth nothing at all")
    func removesEverything() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99), bagItem(2, price: 5)]),
            catalog: [.fixture(id: 1), .fixture(id: 2)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didRemoveEverything()
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
        #expect(viewModel.total == nil)
    }

    @Test("Emptying a bag that is already empty asks nothing of anybody")
    func removingEverythingFromNothing() async {
        let shop = FakeShop(bag: Bag(), catalog: [])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didRemoveEverything()

        #expect(shop.currentBag.isEmpty)
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

