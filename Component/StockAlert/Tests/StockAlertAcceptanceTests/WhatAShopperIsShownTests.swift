import Foundation
import ProductTestSupport
import Testing
import Product
import StockAlert

@MainActor
@Suite("What a shopper with stock alerts is shown")
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: one set of
/// alerts, shown as one list. Which of them have come back is something each product says about
/// itself, so it decides the order they are shown in and nothing else.
struct WhatAShopperIsShownTests {
    @Test("Something still sold out is shown, as still sold out")
    func stillSoldOut() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)
        await shopper.setAlert(productId: 2)

        shopper.theShopSells(soldOut(1), inStock(2))

        #expect(await shopper.shownAsSoldOut() == [pid(1)])
    }

    @Test("Something the shop has again is shown as back, from the very same alerts")
    func back() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)
        await shopper.setAlert(productId: 2)

        shopper.theShopSells(soldOut(1), inStock(2))

        #expect(await shopper.shownAsBack() == [pid(2)])
    }

    /// The invariant the one list has to keep: nothing shown twice, and nothing lost.
    @Test("Every product the shop still sells is shown exactly once")
    func everythingOnce() async {
        let shopper = Shopper(signedInAs: 1)
        for id in 1...4 { await shopper.setAlert(productId: id) }

        shopper.theShopSells(soldOut(1), inStock(2), soldOut(3), inStock(4))

        let shown = await shopper.shown()
        #expect(shown.count == 4)
        #expect(Set(shown) == [pid(1), pid(2), pid(3), pid(4)])
        #expect(Set(await shopper.shownAsSoldOut()).isDisjoint(with: Set(await shopper.shownAsBack())))
    }

    @Test("What has come back is shown first, then what is still sold out, each in the shop's order")
    func backComesFirst() async {
        let shopper = Shopper(signedInAs: 1)
        for id in 1...4 { await shopper.setAlert(productId: id) }

        shopper.theShopSells(soldOut(1), inStock(2), soldOut(3), inStock(4))

        #expect(await shopper.shown() == [pid(2), pid(4), pid(1), pid(3)])
    }

    @Test("Something the shop has stopped selling is not shown")
    func stoppedSelling() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)

        shopper.theShopSells()

        #expect(await shopper.shown() == [])
    }

    @Test("A shopper with no alerts is shown nothing")
    func noAlerts() async {
        let shopper = Shopper(signedInAs: 1)

        #expect(await shopper.shown() == [])
    }

    @Test("A shop that cannot be reached is an answer of its own, not an empty list")
    func theShopCannotBeReached() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)

        shopper.shop.cannotBeReached = true

        #expect(await shopper.alertedProducts() == .failure(.unavailable))
    }
}
