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
        await shopper.looks()

        #expect(shopper.shown.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.shown.bag.total == usd(20))
        #expect(shopper.shown.changes == [.onlySomeLeft(productId: pid(1), available: 2)])
    }

    @Test("Asking for exactly what the shop has is not a shortage")
    func exactlyEnough() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 2)

        shopper.theShopNowSells(shopSells(1, at: 10, remaining: 2))
        await shopper.looks()

        #expect(shopper.shown.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.shown.changes.isEmpty)
    }

    @Test("A line that is both short and repriced is both, because they are two facts")
    func shortAndRepriced() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.theShopNowSells(shopSells(1, at: 12, remaining: 2))
        await shopper.looks()

        #expect(shopper.shown.changes == [
            .priceWentUp(productId: pid(1), from: usd(10), to: usd(12)),
            .onlySomeLeft(productId: pid(1), available: 2)
        ])
        #expect(shopper.shown.bag.total == usd(24))
    }

    @Test("A shopper who saw the shortage and still wants more is cut again, and told again")
    func askingForMoreAgain() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)
        shopper.theShopNowSells(shopSells(1, at: 10, remaining: 2))
        await shopper.visits()

        shopper.changeQuantity(ofProductId: 1, to: 4)
        await shopper.looks()

        #expect(shopper.shown.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.shown.changes == [.onlySomeLeft(productId: pid(1), available: 2)])
    }
}
