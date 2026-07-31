import Foundation
import Testing
import Product
import StockAlert

@MainActor
@Suite("Being told it is back")
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the moment the bell was tapped
/// for. Everything here is about an ask being *answered*, which is the thing nothing used to record
/// — so a shopper's list of what they were waiting for filled up with things that had already come.
struct BeingToldItIsBackTests {
    @Test("Something the shop puts back is no longer being waited for")
    func toldItIsBack() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells(inStock(1))
        await waiter.looks()

        #expect(waiter.alerts.waiting.isEmpty)
        #expect(waiter.alerts.back.map(\.productId) == [pid(1)])
    }

    @Test("Something still sold out is still being waited for")
    func stillWaiting() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theCatalogStillSells(soldOut(1))
        await waiter.looks()

        #expect(waiter.alerts.waiting.map(\.productId) == [pid(1)])
        #expect(waiter.alerts.back.isEmpty)
    }

    /// The reason the catalog is asked at all. An alert service that is behind, or that was told
    /// about a line the shop has since dropped, must not make this app announce something a shopper
    /// cannot then find — sending them looking is worse than saying nothing.
    @Test("A shop that says it is back is not believed when the catalog no longer sells it")
    func theCatalogHasTheLastWord() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells()
        await waiter.looks()

        #expect(waiter.alerts.back.isEmpty)
        #expect(waiter.alerts.waiting.map(\.productId) == [pid(1)])
    }

    @Test("Nor when the catalog still sells it but has none of it")
    func theCatalogSaysStillSoldOut() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells(soldOut(1))
        await waiter.looks()

        #expect(waiter.alerts.back.isEmpty)
    }

    @Test("Only what this shopper asked about, however much the shop volunteers")
    func onlyWhatWasAskedAbout() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theShopPutsBackOnTheShelf(1, 2)
        waiter.theCatalogStillSells(inStock(1), inStock(2))
        await waiter.looks()

        #expect(waiter.alerts.back.map(\.productId) == [pid(1)])
    }

    @Test("The bell goes out once they have been told — there is nothing left to tell them")
    func theBellStopsRinging() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        waiter.watchTheBell(onProductId: 1)
        #expect(waiter.bellIsRinging[pid(1)] == true)

        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells(inStock(1))
        await waiter.looks()

        #expect(waiter.bellIsRinging[pid(1)] == false)
    }

    @Test("Looking twice does not tell them twice")
    func toldOnce() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells(inStock(1))
        await waiter.looks()
        let firstTold = waiter.alerts.back.first?.backSince

        await waiter.looks()

        #expect(waiter.alerts.back.first?.backSince == firstTold)
    }

    @Test("A guest is told nothing, because a guest gave nobody an address")
    func guestsHearNothing() async {
        let waiter = Waiter(signedInAs: nil)

        guard case .failure(let reason) = await waiter.looks() else {
            Issue.record("a guest was caught up on")
            return
        }
        #expect(reason == .unauthenticated)
    }

    @Test("The shop is told what this shopper is waiting on, so it knows what to watch")
    func theShopIsTold() async {
        let waiter = Waiter(signedInAs: 1)

        await waiter.askToBeTold(aboutProductId: 1)
        await waiter.askToBeTold(aboutProductId: 2)

        #expect(Set(waiter.alertService.told) == [pid(1), pid(2)])
    }

    @Test("Changing their mind tells the shop to stop watching too")
    func theShopIsToldToStop() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        await waiter.changeTheirMind(aboutProductId: 1)

        #expect(waiter.alertService.told.isEmpty)
    }

    @Test("Being told it is back survives closing the app")
    func survivesLeaving() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)
        waiter.theShopPutsBackOnTheShelf(1)
        waiter.theCatalogStillSells(inStock(1))
        await waiter.looks()

        let returning = waiter.leaveAndComeBack()

        #expect(returning.alerts.back.map(\.productId) == [pid(1)])
        #expect(returning.alerts.waiting.isEmpty)
    }
}

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

    /// The two lists are the whole of what was asked about, so nothing a shopper is waiting on can
    /// fall between them and go unseen.
    @Test("Between them the two lists account for everything the shop still sells")
    func nothingFallsBetween() async {
        let waiter = Waiter(signedInAs: 1)
        for id in 1...4 { await waiter.askToBeTold(aboutProductId: id) }

        waiter.theCatalogStillSells(soldOut(1), inStock(2), soldOut(3), inStock(4))

        let waiting = await waiter.stillWaitingFor()
        let back = await waiter.backInStock()
        #expect(Set(waiting + back) == [pid(1), pid(2), pid(3), pid(4)])
        #expect(Set(waiting).isDisjoint(with: Set(back)))
    }

    @Test("Something the shop has stopped selling is on neither list")
    func stoppedSellingIsOnNeither() async {
        let waiter = Waiter(signedInAs: 1)
        await waiter.askToBeTold(aboutProductId: 1)

        waiter.theCatalogStillSells()

        #expect(await waiter.stillWaitingFor() == [])
        #expect(await waiter.backInStock() == [])
    }

    @Test("A shopper waiting on nothing is shown nothing, and the shop is not asked")
    func nothingAsked() async {
        let waiter = Waiter(signedInAs: 1)

        #expect(await waiter.stillWaitingFor() == [])
        #expect(await waiter.backInStock() == [])
    }
}
