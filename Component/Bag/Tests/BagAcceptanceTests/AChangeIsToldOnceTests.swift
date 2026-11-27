import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Bag
import Money
import Product

@MainActor
@Suite("A change is told once")
/// Nothing the shop changed is written down anywhere. What a shopper is told is the difference
/// between the bag as it was kept and the bag as the shop says it is now — so keeping the bag as
/// they just saw it is the whole of "they have been told".
struct AChangeIsToldOnceTests {
    @Test("Looking keeps nothing: the bag is still the one they last saw")
    func lookingKeepsNothing() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))

        await shopper.looks()

        #expect(shopper.bag.total == usd(9.99))
    }

    @Test("A shopper who looks again before leaving is told the same thing")
    func stillToldUntilTheyLeave() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.looks()

        await shopper.looks()

        #expect(shopper.shown.changes == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
    }

    @Test("Leaving keeps the bag as they saw it, so there is nothing to tell them next time")
    func leavingKeepsWhatTheySaw() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.visits()

        await shopper.looks()

        #expect(shopper.bag.total == usd(12.99))
        #expect(shopper.shown.changes.isEmpty)
        #expect(shopper.shown.bag.total == usd(12.99))
    }

    @Test("Something that sold out is out of the kept bag once they have seen it, and is not told again")
    func soldOutIsToldOnce() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.choose(productId: 2, atPrice: 20)
        shopper.theShopNowSells(shopHasSoldOutOf(1), shopSells(2, at: 20))
        await shopper.visits()

        await shopper.looks()

        #expect(shopper.bag.items.map(\.id) == [pid(2)])
        #expect(shopper.shown.changes.isEmpty)
    }

    @Test("A line cut to what was left is kept at what was left")
    func cutIsKept() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)
        shopper.theShopNowSells(shopSells(1, at: 10, remaining: 2))

        await shopper.visits()

        #expect(shopper.bag.quantity(of: pid(1)) == 2)
    }

    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)

        shopper.theShopNowSells(shopSells(1, at: 12))
        shopper.theShopNowSells(shopSells(1, at: 15))
        await shopper.looks()

        #expect(shopper.shown.changes == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
        #expect(shopper.shown.bag.total == usd(15))
    }

    @Test("A price that moved again before they left is still one move from what they knew")
    func movedAgainBeforeLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.looks()

        shopper.theShopNowSells(shopSells(1, at: 15))
        await shopper.looks()

        #expect(shopper.shown.changes == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
    }

    @Test("A price that goes up and comes back down before they look is no news")
    func moveAndMoveBack() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.looks()

        shopper.theShopNowSells(shopSells(1, at: 10))
        await shopper.looks()

        #expect(shopper.shown.changes.isEmpty)
        #expect(shopper.shown.bag.total == usd(10))
    }

    @Test("Once a move has been seen, the next one starts from the price they were shown")
    func nextMoveStartsFromWhatTheySaw() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))
        await shopper.visits()

        shopper.theShopNowSells(shopSells(1, at: 15))
        await shopper.looks()

        #expect(shopper.shown.changes == [.priceWentUp(productId: pid(1), from: usd(12), to: usd(15))])
    }

    @Test("A visit that never reached the shop keeps the bag exactly as it was")
    func aVisitThatNeverReachedTheShop() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopSells(1, at: 12))

        await shopper.looksWhileTheShopCannotBeReached()
        shopper.leaves()
        await shopper.looks()

        #expect(shopper.bag.total == usd(10))
        #expect(shopper.shown.changes == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
    }

    @Test("Something that sold out and came back before they looked again is simply in their bag")
    func soldOutAndBackBeforeLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.theShopNowSells(shopHasSoldOutOf(1))
        await shopper.looks()

        shopper.theShopNowSells(shopSells(1, at: 10))
        await shopper.looks()

        #expect(shopper.shown.changes.isEmpty)
        #expect(shopper.shown.bag.total == usd(10))
    }

    @Test("A shopper who closed the app before leaving the bag is still told when they open it again")
    func closingTheAppIsNotLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.looks()

        let returning = await shopper.leaveAndComeBack()
        returning.theShopNowSells(shopSells(1, at: 12.99))
        await returning.looks()

        #expect(returning.shown.changes == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
    }

    @Test("What they saw is still what is kept after the app is closed and opened")
    func whatTheySawSurvivesLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.visits()

        let returning = await shopper.leaveAndComeBack()
        returning.theShopNowSells(shopSells(1, at: 12.99))
        await returning.looks()

        #expect(returning.bag.total == usd(12.99))
        #expect(returning.shown.changes.isEmpty)
    }
}
