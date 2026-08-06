import Foundation
import Testing
import Product
@testable import ProductActionsUI

@MainActor
@Suite("Putting something in the bag")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a shopper in front of a
/// product, driven through the same view models the app builds. Nothing here names a repository or
/// a store.
struct PuttingSomethingInTheBagTests {
    @Test("A shopper taps the bag and it is in their bag, with somewhere to go and see it")
    func addsToBag() async {
        let shown = AProduct()

        shown.bagButton().didTap()
        await shown.settle()

        #expect(shown.bagContains == [pid(1)])
        #expect(shown.snackbarTitles == ["In the Bag"])
    }

    @Test("The count on the button follows what is in the bag")
    func theCountFollows() async {
        let shown = AProduct()
        let button = shown.bagButton()

        button.didTap()
        button.didTap()
        await shown.settle()

        #expect(button.quantity == 2)
    }

    @Test("A bag button can never put in something the shop cannot supply")
    func neverAddsWhatCannotBeSupplied() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))

        shown.bagButton().didTap()
        await shown.settle()

        #expect(shown.bagContains.isEmpty)
        #expect(shown.snackbarTitles.isEmpty)
    }
}

@MainActor
@Suite("Asking to be told when something is back")
/// The bell is the offer a shop can actually keep when it cannot fill a bag. Unlike the snackbar it
/// replaces, the ask is written down — which is what these assert.
struct AskingToBeToldTests {
    @Test("A shopper taps the bell and the ask is recorded, not just acknowledged")
    func recordsTheAsk() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))
        let bell = shown.stockAlertButton()

        bell.didTap()
        await shown.settle()

        #expect(shown.waitingFor == [pid(1)])
        #expect(shown.snackbarTitles == ["You're on the List"])
    }

    @Test("The bell shows whether they have asked, so they are not left guessing")
    func theBellShowsTheAsk() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))
        let bell = shown.stockAlertButton()

        #expect(bell.isWaiting == false)

        bell.didTap()
        await shown.settle()

        #expect(bell.isWaiting == true)
    }

    @Test("Tapping it again is changing their mind, and it stops")
    func changesTheirMind() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))
        let bell = shown.stockAlertButton()

        bell.didTap()
        await shown.settle()
        bell.didTap()
        await shown.settle()

        #expect(shown.waitingFor.isEmpty)
        #expect(bell.isWaiting == false)
        #expect(shown.snackbarTitles == ["You're on the List", "Off the List"])
    }

    @Test("Changing their mind twice in a row leaves them off the list, not on it")
    func changingTheirMindTwiceQuickly() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock))
        let bell = shown.stockAlertButton()

        bell.didTap()
        bell.didTap()
        await shown.settle()

        #expect(shown.waitingFor.isEmpty)
        #expect(bell.isWaiting == false)
        #expect(shown.snackbarTitles == ["You're on the List", "Off the List"])
    }

    @Test("A guest is asked to sign in, because there is nowhere to tell them otherwise")
    func guestIsAskedToSignIn() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock), signedIn: false)
        let bell = shown.stockAlertButton()

        bell.didTap()
        await shown.settle()

        #expect(shown.wasAskedToSignIn)
        #expect(shown.waitingFor.isEmpty)
        #expect(shown.snackbarTitles.isEmpty)
    }

    @Test("A guest who dismisses the sheet is not left thinking they will be told")
    func guestWhoWalksAwayIsNotPromisedAnything() async {
        let shown = AProduct(.fixture(id: 1, availability: .outOfStock), signedIn: false)
        let bell = shown.stockAlertButton()

        bell.didTap()
        await shown.settle()

        #expect(bell.isWaiting == false)
        #expect(shown.snackbarTitles.isEmpty)
    }
}
