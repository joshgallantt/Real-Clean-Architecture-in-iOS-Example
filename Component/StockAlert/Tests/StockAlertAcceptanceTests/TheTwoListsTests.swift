import Foundation
import Testing
import Product
import StockAlert

@MainActor
@Suite("The two lists a shopper is shown")
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: "still waiting
/// on" and "back on the shelf" are two things a shopper would name, so they are two use cases. They
/// were a pair of filters inside a UI container, where no test could reach them and no reader would
/// find them.
struct TheTwoListsTests {
    @Test("What is still sold out is what the shopper is still waiting for")
    func stillWaiting() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        await waiter.askToBeTold(aboutProductId: 2)

        waiter.theCatalogStillSells(soldOut(1), inStock(2))

        #expect(await waiter.stillWaitingFor() == [pid(1)])
    }

    @Test("What the shop has again is what has come back, from the very same asks")
    func comeBack() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        await waiter.askToBeTold(aboutProductId: 2)

        waiter.theCatalogStillSells(soldOut(1), inStock(2))

        #expect(await waiter.backInStock() == [pid(2)])
    }

    /// The invariant the two lists exist to keep: nothing on both, and nothing lost between them.
    @Test("No product is on both lists, and none falls between them")
    func nothingOnBothOrNeither() async {
        let waiter = Waiter(signedInAs: 1)
        for id in 1...4 { await waiter.askToBeTold(aboutProductId: id) }

        waiter.theCatalogStillSells(soldOut(1), inStock(2), soldOut(3), inStock(4))

        let waiting = await waiter.stillWaitingFor()
        let back = await waiter.backInStock()
        #expect(Set(waiting).isDisjoint(with: Set(back)))
        #expect(Set(waiting + back) == [pid(1), pid(2), pid(3), pid(4)])
    }

    @Test("Something the shop has stopped selling is on neither list")
    func stoppedSellingIsOnNeither() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theCatalogStillSells()

        #expect(await waiter.stillWaitingFor() == [])
        #expect(await waiter.backInStock() == [])
    }

    @Test("A shopper waiting on nothing is shown nothing")
    func nothingAsked() async {
        let waiter = Waiter(signedInAs: 1)

        #expect(await waiter.stillWaitingFor() == [])
        #expect(await waiter.backInStock() == [])
    }
}

@MainActor
@Suite("Staying on the waitlist")
/// The modelling decision, asserted rather than assumed. An ask is a record of wanting to be told;
/// whether the shop has any is a fact about the shop. So nothing is taken off on the shopper's
/// behalf, and something that sells out again is waited on again without their asking twice.
struct StayingOnTheWaitlistTests {
    @Test("Something that comes back is still on the waitlist — it has only moved lists")
    func stillWaitlistedWhenBack() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theCatalogStillSells(inStock(1))

        #expect(await waiter.backInStock() == [pid(1)])
        #expect(waiter.alerts.waitingFor(productId: pid(1)))
    }

    @Test("Something that sells out again is waited on again, with nobody asked to ask twice")
    func sellsOutAgain() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        waiter.theCatalogStillSells(inStock(1))
        #expect(await waiter.backInStock() == [pid(1)])

        waiter.theCatalogStillSells(soldOut(1))

        #expect(await waiter.stillWaitingFor() == [pid(1)])
        #expect(await waiter.backInStock() == [])
    }

    @Test("Taking it off takes it off both lists, whichever it was on")
    func takingItOff() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        waiter.theCatalogStillSells(inStock(1))

        await waiter.changeTheirMind(aboutProductId: 1)

        #expect(await waiter.stillWaitingFor() == [])
        #expect(await waiter.backInStock() == [])
        #expect(waiter.alerts.isEmpty)
    }

    @Test("The bell follows the list, not the shelf")
    func theBellFollowsTheList() async {
        let waiter = Waiter(signedInAs: 1)
        waiter.watchTheBell(onProductId: 1)

        await waiter.askToBeTold(aboutProductId: 1)
        #expect(waiter.bellIsRinging[pid(1)] == true)

        await waiter.changeTheirMind(aboutProductId: 1)
        #expect(waiter.bellIsRinging[pid(1)] == false)
    }

    @Test("Asking twice for the same thing is one ask")
    func askingTwice() async {
        let waiter = Waiter(signedInAs: 1)

        await waiter.askToBeTold(aboutProductId: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        #expect(waiter.alerts.count == 1)
    }

    @Test("Taking off something that was never on is not an error")
    func takingOffNothing() async {
        let waiter = Waiter(signedInAs: 1)

        guard case .success = await waiter.changeTheirMind(aboutProductId: 1) else {
            Issue.record("removing something that was not there was reported as a failure")
            return
        }
        #expect(waiter.alerts.isEmpty)
    }

    @Test("The waitlist survives closing the app")
    func survivesLeaving() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        let returning = waiter.leaveAndComeBack()

        #expect(returning.alerts.waitingFor(productId: pid(1)))
    }
}
