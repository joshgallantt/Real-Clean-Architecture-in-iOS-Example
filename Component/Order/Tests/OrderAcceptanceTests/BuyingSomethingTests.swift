import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Order
import Product

@MainActor
@Suite("Buying something")
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: what a shopper did and what
/// they got back, in the words they would use for it.
struct BuyingSomethingTests {
    @Test("A shopper buys one thing and is given an order for it")
    func buyOneThing() async {
        let buyer = Buyer()

        let result = await buyer.buy(item(1, at: 9.99))

        let order = try? result.get()
        #expect(order?.lines.map(\.productId) == [pid(1)])
        #expect(order?.total == usd(9.99))
    }

    @Test("An order is worth the sum of its lines, however many of each there are")
    func totalsAcrossLines() async {
        let buyer = Buyer()

        let result = await buyer.buy(item(1, quantity: 3, at: 10), item(2, at: 5.50))

        #expect((try? result.get())?.total == usd(35.50))
    }

    @Test("What was bought shows up in what the shopper has bought")
    func buyingAddsToHistory() async {
        let buyer = Buyer()

        await buyer.buy(item(1, at: 9.99))

        #expect(buyer.orders.count == 1)
        #expect(buyer.orders.mostRecent?.total == usd(9.99))
    }

    @Test("Two orders are listed newest first, however close together they were placed")
    func newestFirst() async {
        let buyer = Buyer()

        await buyer.buy(item(1, at: 9.99))
        await buyer.buy(item(2, at: 20))

        #expect(buyer.orders.count == 2)
        #expect(buyer.orders.mostRecent?.total == usd(20))
    }

    @Test("Each order is its own, even when somebody buys the same thing twice")
    func sameThingTwiceIsTwoOrders() async {
        let buyer = Buyer()

        await buyer.buy(item(1, at: 9.99))
        await buyer.buy(item(1, at: 9.99))

        #expect(buyer.orders.count == 2)
        #expect(Set(buyer.orders.all.map(\.id)).count == 2)
    }

    @Test("An order records what was paid, not what the thing costs later")
    func priceIsFrozen() async {
        let buyer = Buyer()

        await buyer.buy(item(1, at: 9.99))

        #expect(buyer.orders.mostRecent?.lines.first?.pricePaid == usd(9.99))
    }

    @Test("Buying nothing is refused rather than quietly making an empty order")
    func buyingNothing() async {
        let buyer = Buyer()

        let result = await buyer.buy()

        #expect(result == .failure(.nothingToOrder))
        #expect(buyer.orders.isEmpty)
    }
}
