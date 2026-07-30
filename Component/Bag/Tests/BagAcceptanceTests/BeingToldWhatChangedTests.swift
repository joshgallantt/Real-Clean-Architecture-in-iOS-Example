import Foundation
import Testing
import Bag
import Money
import Product

@MainActor
@Suite("Being told what the shop changed")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: what the shopper is *told*, in the
/// words they would be told it. Whether a notice is worth telling depends on the bag it is about,
/// so it is asserted where both are visible — through the same use cases the bag screen is given.
struct BeingToldWhatChangedTests {
    @Test("A shop asking the same prices has nothing to tell anyone")
    func nothingChanged() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopSells(1, at: 9.99))

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(9.99))
    }

    @Test("A shopper is told a price went up, and the bag is worth the new price")
    func priceWentUp() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopSells(1, at: 12.99))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("A price that came down is passed on — the shopper should get the better one")
    func priceWentDown() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopSells(1, at: 4.99))

        #expect(shopper.news.priceMoves == [.priceWentDown(productId: pid(1), from: usd(9.99), to: usd(4.99))])
        #expect(shopper.bag.total == usd(4.99))
    }

    @Test("A shopper is told something has gone, and it is out of their bag")
    func soldOut() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopHasSoldOutOf(1))

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(shopper.bag.isEmpty)
    }

    @Test("Something the shop has stopped selling goes the same way as something sold out")
    func discontinued() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopHasDiscontinued(1))

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(shopper.bag.isEmpty)
    }

    @Test("What something's price did on the way out is not worth saying")
    func soldOutAndRepriced() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(ShopSays(productId: pid(1), price: usd(12.99), availability: .outOfStock))

        #expect(shopper.news.all == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("A product the shop was not asked about is left exactly as it was")
    func notAskedAbout() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.shopSays(shopSells(2, at: 49.99))

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(59.98))
    }

    @Test("A bag the shop has emptied is empty, and says why")
    func everythingWent() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.shopSays(shopHasSoldOutOf(1), shopHasSoldOutOf(2))

        #expect(shopper.bag.isEmpty)
        #expect(shopper.bag.total == nil)
        #expect(Set(shopper.news.noLongerAvailable.map(\.productId)) == [pid(1), pid(2)])
    }

    @Test("Price moves and disappearances are kept apart, because they are told apart")
    func twoKindsOfNews() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.shopSays(shopHasSoldOutOf(1), shopSells(2, at: 59.99))

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(2), from: usd(49.99), to: usd(59.99))])
        #expect(shopper.bag.items.map(\.id) == [pid(2)])
    }

    @Test("A shopper away a long time hears about everything that moved")
    func aLotHasHappened() {
        let shopper = Shopper()
        for (id, price) in [(1, Decimal(9.99)), (2, 49.99), (3, 19.99), (4, 5.99)] {
            shopper.choose(productId: id, atPrice: price)
        }

        shopper.shopSays(
            shopSells(1, at: 12.99),
            shopHasSoldOutOf(2),
            shopSells(3, at: 19.99),
            shopHasSoldOutOf(4)
        )

        #expect(Set(shopper.news.noLongerAvailable.map(\.productId)) == [pid(2), pid(4)])
        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(Set(shopper.bag.items.map(\.id)) == [pid(1), pid(3)])
    }

    @Test("An empty bag has nothing to catch up on")
    func emptyBag() {
        let shopper = Shopper()

        shopper.shopSays(shopHasSoldOutOf(1))

        #expect(shopper.bag.isEmpty)
        #expect(shopper.news.isEmpty)
    }
}

@MainActor
@Suite("Asking for more than the shop has")
struct MoreThanTheShopHasTests {
    @Test("A line comes down to what the shop can actually supply, and the shopper is told")
    func quantityIsCapped() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.shopSays(shopSells(1, at: 10, remaining: 2))

        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.bag.total == usd(20))
        #expect(shopper.news.shortages == [.onlySomeLeft(productId: pid(1), available: 2)])
    }

    @Test("Asking for exactly what the shop has is not a shortage")
    func exactlyEnough() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 2)

        shopper.shopSays(shopSells(1, at: 10, remaining: 2))

        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.news.isEmpty)
    }

    @Test("A line that is both short and repriced is both, because they are two facts")
    func shortAndRepriced() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.shopSays(shopSells(1, at: 12, remaining: 2))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
        #expect(shopper.news.shortages == [.onlySomeLeft(productId: pid(1), available: 2)])
        #expect(shopper.bag.total == usd(24))
    }

    @Test("A shortage next to a price move does not swallow the price the shopper knew")
    func shortageDoesNotHideThePriceTheyKnew() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.shopSays(shopSells(1, at: 12, remaining: 2))
        shopper.shopSays(shopSells(1, at: 15, remaining: 2))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
    }
}

@MainActor
@Suite("News that piles up while nobody is looking")
struct NewsThatPilesUpTests {
    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.shopSays(shopSells(1, at: 12))
        shopper.shopSays(shopSells(1, at: 15))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
        #expect(shopper.bag.total == usd(15))
    }

    @Test("A price that goes up and comes back down is no longer news")
    func moveAndMoveBack() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.shopSays(shopSells(1, at: 12))
        shopper.shopSays(shopSells(1, at: 10))

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(10))
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.shopSays(shopSells(1, at: 12))
        shopper.shopSays(shopSells(1, at: 8))

        #expect(shopper.news.priceMoves == [.priceWentDown(productId: pid(1), from: usd(10), to: usd(8))])
    }

    @Test("News survives a catch-up that did not cover that product")
    func survivesAPartialLookup() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.shopSays(shopSells(1, at: 12))

        shopper.shopSays()

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
    }

    @Test("Being told twice that something has gone is still one piece of news")
    func goneIsNotRepeated() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.shopSays(shopHasSoldOutOf(1))
        shopper.shopSays(shopHasSoldOutOf(1))

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("Saying they have seen it clears the notice without touching the bag")
    func seenIt() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.shopSays(shopSells(1, at: 12.99))

        shopper.seen(productId: 1)

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("Once a move has been seen, the next one starts from the price they were shown")
    func nextMoveStartsFromWhatTheySaw() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.shopSays(shopSells(1, at: 12))
        shopper.seen(productId: 1)

        shopper.shopSays(shopSells(1, at: 15))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(12), to: usd(15))])
    }

    @Test("Saying one product has been seen leaves the others still waiting")
    func seenOneOfTwo() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.choose(productId: 2, atPrice: 20)
        shopper.shopSays(shopHasSoldOutOf(1), shopHasSoldOutOf(2))

        shopper.seen(productId: 2)

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("Choosing something again spends the news that it had gone")
    func choosingAgainSpendsTheNews() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.shopSays(shopHasSoldOutOf(1))

        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.news.isEmpty)
    }

    @Test("A price move about something the shopper has since put back is not shown")
    func priceMoveForSomethingRemoved() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.shopSays(shopSells(1, at: 12))

        shopper.remove(productId: 1)

        #expect(shopper.news.isEmpty)
    }
}
