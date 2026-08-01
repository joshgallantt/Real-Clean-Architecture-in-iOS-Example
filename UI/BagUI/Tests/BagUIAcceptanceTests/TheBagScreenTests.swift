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
    private let navigation = StubNavigation()

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

    private func makeShop(
        items: [BagItem] = [bagItem(1, price: 9.99)],
        notices: Notices = Notices(),
        catalog: [Product] = [.fixture(id: 1)]
    ) -> FakeShop {
        FakeShop(bag: Bag(items: items), notices: notices, catalog: catalog)
    }

    @Test("Something the shop has run out of still shows what it was")
    func outOfStockRowsKeepTheirNames() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.notices(in: .outOfStock).first?.name == "Product 1")
        #expect(viewModel.notices(in: .outOfStock).first?.imageURL != nil)
    }

    @Test("A notice waiting from a previous visit still says what it is about")
    func noticesFromLastTimeAreNamed() async {
        let shop = makeShop(
            items: [],
            notices: Notices([.outOfStock(productId: pid(7))]),
            catalog: [.fixture(id: 7, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.notices(in: .outOfStock).map(\.id) == [pid(7)])
        #expect(viewModel.notices(in: .outOfStock).first?.name == "Product 7")
    }

    @Test("A price notice about something still in the bag keeps its name too")
    func priceNoticesAreNamed() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 19.99)])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.notices(in: .priceWentUp).first?.name == "Product 1")
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

        #expect(shop.currentNotices.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(viewModel.notices(in: .priceWentUp).map(\.id) == [pid(1)])
        #expect(viewModel.notices(in: .outOfStock).isEmpty)
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
        #expect(viewModel.notices(in: .outOfStock).map(\.id) == [pid(1)])
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Something the shop no longer answers about leaves quietly, with no section of its own")
    func stoppedSellingSaysNothing() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [
                .fixture(id: 1, availability: .outOfStock)
            ]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.notices(in: .outOfStock).map(\.id) == [pid(1)])
        #expect(viewModel.noticeSections.count == 1)
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
                .fixture(id: 3, availability: .inStock(remaining: 2)),
                .fixture(id: 4, availability: .inStock(remaining: 1)),
                .fixture(id: 5, price: 8)
            ]
        )
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(viewModel.notices(in: .outOfStock).first?.says == .nothing)

        // How many are left, and what it costs now, are the two things a heading cannot say.
        let shortages = viewModel.notices(in: .onlySomeLeft).map(\.says)
        #expect(shortages.contains(.howManyLeft("2 left")))
        #expect(shortages.contains(.howManyLeft("Last one")))

        #expect(viewModel.notices(in: .priceWentUp).first?.says == .priceMoved(
            NoticeRow.PriceMove(was: usd(5).formatted(), now: usd(8).formatted(), isCheaper: false)
        ))
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

        #expect(dearerScreen.notices(in: .priceWentUp).first?.says == .priceMoved(
            NoticeRow.PriceMove(was: usd(9.99).formatted(), now: usd(12.99).formatted(), isCheaper: false)
        ))

        #expect(cheaperScreen.notices(in: .priceWentDown).first?.says == .priceMoved(
            NoticeRow.PriceMove(was: usd(9.99).formatted(), now: usd(4.99).formatted(), isCheaper: true)
        ))
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
        #expect(viewModel.notices(in: .priceWentUp).map(\.id) == [pid(1)])

        viewModel.didRemoveChangedItem(productId: pid(1))
        await settle(shop, untilAskedTimes: 2)

        #expect(shop.currentBag.isEmpty)
        #expect(viewModel.notices(in: .priceWentUp).isEmpty)
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

        #expect(viewModel.notices(in: .priceWentUp).map(\.id) == [pid(1)])
        #expect(viewModel.notices(in: .priceWentDown).map(\.id) == [pid(2)])
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

        viewModel.didAcceptAll(.priceWentUp)

        #expect(viewModel.notices(in: .priceWentUp).isEmpty)
        #expect(viewModel.notices(in: .priceWentDown).map(\.id) == [pid(2)])
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

        #expect(plenty.currentNotices.isEmpty)
        #expect(none.currentNotices.of(.outOfStock) == [.outOfStock(productId: pid(1))])
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

    @Test("Tapping Okay clears the notice without going back to the shop")
    func acknowledgingDoesNotAsk() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)
        let asksSoFar = shop.lookups.count
        #expect(viewModel.notices(in: .priceWentUp).count == 1)

        viewModel.didAcceptAll(.priceWentUp)
        await settle(shop)

        #expect(shop.lookups.count == asksSoFar)
        #expect(viewModel.notices(in: .priceWentUp).isEmpty)
    }


    /// The premise of this test used to be the opposite, and it was wrong: a shop that answers and
    /// describes nothing has told the bag something. Silence about a product it was *asked* about is
    /// the only way a shop says it has stopped selling one, so the line goes and the shopper is told.
    ///
    /// A shop that could not be reached at all is the other case, below, and it must not do this —
    /// a bag emptied by a dropped connection would be the worst bug on this screen.
    @Test("A shop that answers and describes nothing has stopped selling all of it")
    func answeringWithNothingMeansStopped() async {
        let shop = makeShop(catalog: [])
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentBag.isEmpty)
        #expect(shop.currentNotices.isEmpty)
        #expect(viewModel.hasNews == false)
    }

    @Test("A shop that cannot be reached leaves the bag exactly as it was")
    func aShopThatCannotBeReachedChangesNothing() async {
        let shop = makeShop(catalog: [])
        shop.cannotBeReached = true
        let viewModel = makeViewModel(shop: shop)

        viewModel.onAppear()
        await settle(shop)

        #expect(shop.currentNotices.isEmpty)
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
    private let navigation = StubNavigation()

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
        viewModel.onAppear()
        await settle(shop)
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
        viewModel.onAppear()
        await settle(shop)
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
        viewModel.onAppear()
        await settle(shop)

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


@MainActor
@Suite("Going from the bag to a product", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: a shopper taps a line and
/// expects the thing. These went untested while opening a product was called straight out of the
/// view — there was a `StubNavigation` and nothing that could assert on it.
struct GoingFromTheBagToAProductTests {
    private let navigation = StubNavigation()

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
        viewModel.onAppear()
        await settle(shop)

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts == [pid(1)])
    }

    @Test("Tapping something that sold out opens it — it is coming back, and the page is where you wait")
    func tappingAnOutOfStockNotice() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99)]),
            catalog: [.fixture(id: 1, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts == [pid(1)])
    }

    @Test("Tapping something repriced opens it, because that is where the decision gets made")
    func tappingAPriceNotice() async {
        let shop = FakeShop(
            bag: Bag(items: [bagItem(1, price: 9.99)]),
            catalog: [.fixture(id: 1, price: 12.99)]
        )
        let viewModel = makeViewModel(shop: shop)
        viewModel.onAppear()
        await settle(shop)

        viewModel.didTapRow(productId: pid(1))

        #expect(navigation.openedProducts == [pid(1)])
    }

}
