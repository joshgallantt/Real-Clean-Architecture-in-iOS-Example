import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Bag
import Money
import Product

@MainActor
@Suite("Being told what the shop changed")
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: what the shopper is *told*, in the
/// words they would be told it. Whether a notice is worth telling depends on the bag it is about,
/// so it is asserted where both are visible — through the same use cases the bag screen is given.
struct BeingToldWhatChangedTests {
    @Test("A shop asking the same prices has nothing to tell anyone")
    func nothingChanged() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.theShopNowSells(shopSells(1, at: 9.99))
        await shopper.comesBack()

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(9.99))
    }

    @Test("A shopper is told a price went up, and the bag is worth the new price")
    func priceWentUp() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("A price that came down is passed on — the shopper should get the better one")
    func priceWentDown() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.theShopNowSells(shopSells(1, at: 4.99))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentDown(productId: pid(1), from: usd(9.99), to: usd(4.99))])
        #expect(shopper.bag.total == usd(4.99))
    }

    @Test("A shopper is told something has gone, and it is out of their bag")
    func soldOut() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
        #expect(shopper.bag.isEmpty)
    }

    @Test("Something the shop no longer answers about leaves the bag, and says nothing")
    func stoppedSelling() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        /// Asked about, and not described. That silence is the whole signal — and there is nothing
        /// a shopper can do about it, so they are not handed a notice to dismiss.
        shopper.theShopNowSells()
        await shopper.comesBack()

        #expect(shopper.bag.isEmpty)
        #expect(shopper.news.isEmpty)
    }

    @Test("A sell-out is news; something stopped is not, because only one can be waited for")
    func toldApart() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 5)

        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
        #expect(shopper.news.gone.count == 1)
        #expect(shopper.bag.isEmpty)
    }

    @Test("What something's price did on the way out is not worth saying")
    func soldOutAndRepriced() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        /// Sold out, and dearer than the shopper last saw. What its price did on the way out is not
        /// something they can act on, so they are told the one thing they can.
        shopper.theShopNowSells(shopHasSoldOutOf(1, at: 12.99))
        await shopper.comesBack()

        #expect(shopper.news.all == [.outOfStock(productId: pid(1))])
    }

    @Test("A catch-up that never reached the shop concludes nothing about anything")
    func theShopWasNotReached() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        await shopper.theShopCannotBeReached()

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(59.98))
    }

    @Test("Being asked about and not described is what stopped selling looks like")
    func silenceMeansStopped() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.theShopNowSells(shopSells(2, at: 49.99))
        await shopper.comesBack()

        #expect(shopper.bag.items.map(\.id) == [pid(2)])
        #expect(shopper.bag.total == usd(49.99))
        #expect(shopper.news.isEmpty)
    }

    @Test("A bag the shop has emptied is empty, and says why")
    func everythingWent() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.theShopNowSells(shopHasSoldOutOf(1), shopHasSoldOutOf(2))
        await shopper.comesBack()

        #expect(shopper.bag.isEmpty)
        #expect(shopper.bag.total == nil)
        #expect(Set(shopper.news.of(.outOfStock).map(\.productId)) == [pid(1), pid(2)])
    }

    @Test("Price moves and disappearances are kept apart, because they are told apart")
    func twoKindsOfNews() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.theShopNowSells(shopHasSoldOutOf(1), shopSells(2, at: 59.99))
        await shopper.comesBack()

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(2), from: usd(49.99), to: usd(59.99))])
        #expect(shopper.bag.items.map(\.id) == [pid(2)])
    }

    @Test("A shopper away a long time hears about everything that moved")
    func aLotHasHappened() async {
        let shopper = Shopper()
        for (id, price) in [(1, Decimal(9.99)), (2, 49.99), (3, 19.99), (4, 5.99)] {
            shopper.choose(productId: id, atPrice: price)
        }

        shopper.theShopNowSells(
            shopSells(1, at: 12.99),
            shopHasSoldOutOf(2),
            shopSells(3, at: 19.99),
            shopHasSoldOutOf(4)
        )
        await shopper.comesBack()

        #expect(Set(shopper.news.of(.outOfStock).map(\.productId)) == [pid(2), pid(4)])
        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(Set(shopper.bag.items.map(\.id)) == [pid(1), pid(3)])
    }

    @Test("An empty bag has nothing to catch up on")
    func emptyBag() async {
        let shopper = Shopper()

        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        #expect(shopper.bag.isEmpty)
        #expect(shopper.news.isEmpty)
    }
}
