import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Order
import Product

@MainActor
@Suite("When buying does not work")
/// A shopper is told which of the two it was, because they would do different things about them.
struct WhenBuyingDoesNotWorkTests {
    @Test("A guest is asked to sign in rather than sold anything")
    func guestsCannotBuy() async {
        let buyer = Buyer(signedInAs: nil)

        let result = await buyer.buy(item(1, at: 9.99))

        #expect(result == .failure(.unauthenticated))
        #expect(buyer.orders.isEmpty)
    }

    @Test("A declined payment leaves no order behind")
    func declinedLeavesNoOrder() async {
        let buyer = Buyer(theShopTakesPayment: .declines)

        let result = await buyer.buy(item(1, at: 9.99))

        #expect(result == .failure(.paymentDeclined))
        #expect(buyer.orders.isEmpty)
    }

    @Test("A processor that cannot be reached is told apart from a decline")
    func unavailableIsNotADecline() async {
        let buyer = Buyer(theShopTakesPayment: .unavailable)

        let result = await buyer.buy(item(1, at: 9.99))

        #expect(result == .failure(.unavailable))
        #expect(buyer.orders.isEmpty)
    }

    @Test("A shopper who signs in after being turned away can then buy")
    func signingInThenBuying() async {
        let buyer = Buyer(signedInAs: nil)
        #expect(await buyer.buy(item(1, at: 9.99)) == .failure(.unauthenticated))

        buyer.signIn(asUserId: 7)

        #expect((try? await buyer.buy(item(1, at: 9.99)).get())?.total == usd(9.99))
    }
}
