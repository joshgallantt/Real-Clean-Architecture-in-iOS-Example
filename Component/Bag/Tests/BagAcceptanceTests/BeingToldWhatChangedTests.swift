import Foundation
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

    @Test("Something the shop no longer answers about has been stopped, and leaves the bag")
    func discontinued() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        /// Asked about, and not described. That silence is the whole signal.
        shopper.theShopNowSells()
        await shopper.comesBack()

        #expect(shopper.news.of(.discontinued) == [.discontinued(productId: pid(1))])
        #expect(shopper.news.of(.outOfStock).isEmpty)
        #expect(shopper.bag.isEmpty)
    }

    @Test("A sell-out and a discontinuation are not the same news, because they are not the same to a shopper")
    func toldApart() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 5)

        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
        #expect(shopper.news.of(.discontinued) == [.discontinued(productId: pid(2))])
        #expect(shopper.news.gone.count == 2)
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

        #expect(shopper.news.of(.discontinued) == [.discontinued(productId: pid(1))])
        #expect(shopper.bag.items.map(\.id) == [pid(2)])
        #expect(shopper.bag.total == usd(49.99))
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

@MainActor
@Suite("Asking for more than the shop has")
struct MoreThanTheShopHasTests {
    @Test("A line comes down to what the shop can actually supply, and the shopper is told")
    func quantityIsCapped() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.theShopNowSells(shopSells(1, at: 10, remaining: 2))
        await shopper.comesBack()

        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.bag.total == usd(20))
        #expect(shopper.news.of(.onlySomeLeft) == [.onlySomeLeft(productId: pid(1), available: 2)])
    }

    @Test("Asking for exactly what the shop has is not a shortage")
    func exactlyEnough() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 2)

        shopper.theShopNowSells(shopSells(1, at: 10, remaining: 2))
        await shopper.comesBack()

        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.news.isEmpty)
    }

    @Test("A line that is both short and repriced is both, because they are two facts")
    func shortAndRepriced() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.theShopNowSells(shopSells(1, at: 12, remaining: 2))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
        #expect(shopper.news.of(.onlySomeLeft) == [.onlySomeLeft(productId: pid(1), available: 2)])
        #expect(shopper.bag.total == usd(24))
    }

    @Test("A shortage next to a price move does not swallow the price the shopper knew")
    func shortageDoesNotHideThePriceTheyKnew() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.theShopNowSells(shopSells(1, at: 12, remaining: 2))
        await shopper.comesBack()
        shopper.theShopNowSells(shopSells(1, at: 15, remaining: 2))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
    }
}

@MainActor
@Suite("News that piles up while nobody is looking")
struct NewsThatPilesUpTests {
    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()
        shopper.theShopNowSells(shopSells(1, at: 15))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
        #expect(shopper.bag.total == usd(15))
    }

    @Test("A price that goes up and comes back down is no longer news")
    func moveAndMoveBack() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()
        shopper.theShopNowSells(shopSells(1, at: 10))
        await shopper.comesBack()

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(10))
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()
        shopper.theShopNowSells(shopSells(1, at: 8))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentDown(productId: pid(1), from: usd(10), to: usd(8))])
    }

    @Test("News survives a catch-up that never reached the shop")
    func survivesAFailedLookup() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()

        await shopper.theShopCannotBeReached()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
    }

    @Test("Being told twice that something has gone is still one piece of news")
    func goneIsNotRepeated() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()
        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
    }

    @Test("Saying they have seen it clears the notice without touching the bag")
    func seenIt() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.comesBack()

        shopper.seen(productId: 1)

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("Once a move has been seen, the next one starts from the price they were shown")
    func nextMoveStartsFromWhatTheySaw() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()
        shopper.seen(productId: 1)

        shopper.theShopNowSells(shopSells(1, at: 15))
        await shopper.comesBack()

        #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(12), to: usd(15))])
    }

    @Test("Saying one product has been seen leaves the others still waiting")
    func seenOneOfTwo() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.choose(productId: 2, atPrice: 20)
        shopper.theShopNowSells(shopHasSoldOutOf(1), shopHasSoldOutOf(2))
        await shopper.comesBack()

        shopper.seen(productId: 2)

        #expect(shopper.news.of(.outOfStock) == [.outOfStock(productId: pid(1))])
    }

    @Test("Choosing something again spends the news that it had gone")
    func choosingAgainSpendsTheNews() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.comesBack()

        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.news.isEmpty)
    }

    @Test("A price move about something the shopper has since put back is not shown")
    func priceMoveForSomethingRemoved() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.comesBack()

        shopper.remove(productId: 1)

        #expect(shopper.news.isEmpty)
    }
}
