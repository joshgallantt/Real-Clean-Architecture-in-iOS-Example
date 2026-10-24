import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Bag
import Money
import Product

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
