import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Bag
import Money
import Product

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
