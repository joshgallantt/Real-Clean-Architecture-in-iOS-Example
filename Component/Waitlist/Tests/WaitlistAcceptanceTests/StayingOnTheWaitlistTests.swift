import Foundation
import ProductTestSupport
import Testing
import Product
import Waitlist

@MainActor
@Suite("Staying on the waitlist")
/// The modelling decision, asserted rather than assumed. Being on the waitlist is wanting to be
/// told; whether the shop has any is a fact about the shop. So nothing is taken off on the
/// shopper's behalf, and something that sells out again is waited on again without their joining
/// twice.
struct StayingOnTheWaitlistTests {
    @Test("Something that comes back is still on the waitlist — it has only moved lists")
    func stillWaitlistedWhenBack() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)

        shopper.theShopSells(inStock(1))

        #expect(await shopper.backInStock() == [pid(1)])
        #expect(shopper.waitlist.contains(productId: pid(1)))
    }

    @Test("Something that sells out again is waited on again, with nobody asked to join twice")
    func sellsOutAgain() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)
        shopper.theShopSells(inStock(1))
        #expect(await shopper.backInStock() == [pid(1)])

        shopper.theShopSells(soldOut(1))

        #expect(await shopper.stillSoldOut() == [pid(1)])
        #expect(await shopper.backInStock() == [])
    }

    @Test("Leaving takes it off both lists, whichever it was on")
    func leaving() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)
        shopper.theShopSells(inStock(1))

        await shopper.leave(productId: 1)

        #expect(await shopper.stillSoldOut() == [])
        #expect(await shopper.backInStock() == [])
        #expect(shopper.waitlist.isEmpty)
    }

    @Test("The bell follows the waitlist, not the shelf")
    func theBellFollowsTheWaitlist() async {
        let shopper = Shopper(signedInAs: 1)
        shopper.watchTheBell(onProductId: 1)
        shopper.theShopSells(inStock(1))

        await shopper.join(productId: 1)
        #expect(shopper.bellIsOn[pid(1)] == true)

        await shopper.leave(productId: 1)
        #expect(shopper.bellIsOn[pid(1)] == false)
    }
}
