import Foundation
import Testing
import Money
import Order
import Product

@MainActor
@Suite("Coming back to what you bought")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: driven over a real
/// `FileOrderStore`, so what survives is decided by the code that will actually have to survive it.
struct ComingBackToYourOrdersTests {
    @Test("An order is still there after closing the app and opening it again")
    func ordersSurviveLeaving() async {
        let buyer = Buyer()
        await buyer.buy(item(1, quantity: 2, at: 9.99))

        let returning = await buyer.leaveAndComeBack()

        #expect(returning.orders.count == 1)
        #expect(returning.orders.mostRecent?.total == usd(19.98))
        #expect(returning.orders.mostRecent?.lines.first?.quantity == 2)
    }

    @Test("An order read back off disk is worth exactly what it was worth when it was placed")
    func totalsSurviveExactly() async {
        let buyer = Buyer()
        await buyer.buy(item(1, quantity: 3, at: 0.10), item(2, at: 19.99))

        let returning = await buyer.leaveAndComeBack()

        #expect(returning.orders.mostRecent?.total == usd(20.29))
    }

    @Test("Orders belong to whoever placed them, and another shopper sees none of them")
    func ordersAreOwned() async {
        let buyer = Buyer(signedInAs: 1)
        await buyer.buy(item(1, at: 9.99))
        await buyer.writesToSettle()

        buyer.signOut()
        #expect(buyer.orders.isEmpty)

        buyer.signIn(asUserId: 2)
        #expect(buyer.orders.isEmpty)
    }

    @Test("Signing back in brings a shopper's own orders back")
    func signingBackInRestoresThem() async {
        let buyer = Buyer(signedInAs: 1)
        await buyer.buy(item(1, at: 9.99))
        await buyer.writesToSettle()

        buyer.signOut()
        buyer.signIn(asUserId: 1)

        #expect(buyer.orders.count == 1)
        #expect(buyer.orders.mostRecent?.total == usd(9.99))
    }

    @Test("A shopper who has bought nothing has nothing to look at")
    func nothingBought() async {
        let buyer = Buyer()

        #expect(buyer.orders.isEmpty)
        #expect(buyer.orders.mostRecent == nil)
    }
}
