import Foundation
import ProductTestSupport
import Testing
import Product
import Waitlist

@MainActor
@Suite("The two lists a shopper is shown")
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: "still sold
/// out" and "back in stock" are two things a shopper would name, so they are two use cases over one
/// waitlist.
struct TheTwoListsTests {
    @Test("What is still sold out is what the shopper is still waiting for")
    func stillSoldOut() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)
        await shopper.join(productId: 2)

        shopper.theShopSells(soldOut(1), inStock(2))

        #expect(await shopper.stillSoldOut() == [pid(1)])
    }

    @Test("What the shop has again is what has come back, from the very same waitlist")
    func backInStock() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)
        await shopper.join(productId: 2)

        shopper.theShopSells(soldOut(1), inStock(2))

        #expect(await shopper.backInStock() == [pid(2)])
    }

    /// The invariant the two lists exist to keep: nothing on both, and nothing lost between them.
    @Test("No product is on both lists, and none falls between them")
    func nothingOnBothOrNeither() async {
        let shopper = Shopper(signedInAs: 1)
        for id in 1...4 { await shopper.join(productId: id) }

        shopper.theShopSells(soldOut(1), inStock(2), soldOut(3), inStock(4))

        let soldOut = await shopper.stillSoldOut()
        let back = await shopper.backInStock()
        #expect(Set(soldOut).isDisjoint(with: Set(back)))
        #expect(Set(soldOut + back) == [pid(1), pid(2), pid(3), pid(4)])
    }

    @Test("Something the shop has stopped selling is on neither list")
    func stoppedSellingIsOnNeither() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.join(productId: 1)

        shopper.theShopSells()

        #expect(await shopper.stillSoldOut() == [])
        #expect(await shopper.backInStock() == [])
    }

    @Test("A shopper waiting on nothing is shown nothing")
    func nothingJoined() async {
        let shopper = Shopper(signedInAs: 1)

        #expect(await shopper.stillSoldOut() == [])
        #expect(await shopper.backInStock() == [])
    }
}

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
