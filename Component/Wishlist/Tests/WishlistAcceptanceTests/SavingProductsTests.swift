import Foundation
import Testing
import Product
import Wishlist

@MainActor
@Suite("Saving products for later")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. Every test here is
/// something a shopper would notice.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct SavingProductsTests {
    @Test("A signed-in shopper saves two things and finds both waiting, most recent first")
    func savesTwoThings() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        #expect(shopper.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Tapping the heart twice on the same product saves it once")
    func savingTwice() async {
        let shopper = Saver(signedInAs: 42)

        await shopper.save(productId: 1)
        await shopper.save(productId: 1)

        #expect(shopper.wishlist.itemCount == 1)
    }

    @Test("Saving something already saved does not shuffle it back to the top")
    func savingAgainDoesNotReorder() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        await shopper.save(productId: 1)

        #expect(shopper.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Unsaving takes it out and leaves the rest")
    func unsaving() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        await shopper.unsave(productId: 1)

        #expect(shopper.wishlist.items.map(\.id) == [pid(2)])
    }

    @Test("Unsaving something that was never saved changes nothing")
    func unsavingSomethingNeverSaved() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)

        await shopper.unsave(productId: 99)

        #expect(shopper.wishlist.items.map(\.id) == [pid(1)])
    }

    @Test("The heart on a product fills and empties as that product is saved and unsaved")
    func theHeartFollowsOneProduct() async {
        let shopper = Saver(signedInAs: 42)
        shopper.watchTheHeart(onProductId: 7)

        #expect(shopper.heartIsFilled[pid(7)] == false)

        await shopper.save(productId: 7)
        #expect(shopper.heartIsFilled[pid(7)] == true)

        await shopper.unsave(productId: 7)
        #expect(shopper.heartIsFilled[pid(7)] == false)
    }

    @Test("The heart on a product ignores the rest of the list moving around it")
    func theHeartIgnoresEverythingElse() async {
        let shopper = Saver(signedInAs: 42)
        shopper.watchTheHeart(onProductId: 7)
        await shopper.save(productId: 7)

        await shopper.save(productId: 99)
        await shopper.unsave(productId: 99)

        #expect(shopper.heartIsFilled[pid(7)] == true)
    }
}

@MainActor
@Suite("A wishlist belongs to somebody")
/// Requiring an account is a business rule, so it is met here as a shopper meets it — as an answer
/// from the operation they attempted, not as a check they had to remember to make first.
struct AWishlistBelongsToSomebodyTests {
    @Test("A guest is asked to sign in rather than quietly saving nothing")
    func guestIsAskedToSignIn() async {
        let shopper = Saver()

        let outcome = await shopper.save(productId: 1)

        #expect(outcome.failure == .unauthenticated)
        #expect(shopper.wishlist.isEmpty)
    }

    @Test("A guest cannot unsave either — there is no list of theirs to change")
    func guestCannotUnsave() async {
        let shopper = Saver()

        #expect(await shopper.unsave(productId: 1).failure == .unauthenticated)
    }

    @Test("Signing in after being asked, the shopper can save what they were after")
    func signingInThenSaving() async {
        let shopper = Saver()
        #expect(await shopper.save(productId: 1).failure == .unauthenticated)

        shopper.signIn(asUserId: 42)

        #expect(await shopper.save(productId: 1).failure == nil)
        #expect(shopper.wishlist.items.map(\.id) == [pid(1)])
    }

    @Test("A shopper's saved products are still there when they come back")
    func listSurvivesLeaving() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)
        await shopper.save(productId: 2)

        let returning = await shopper.leaveAndComeBack()

        #expect(returning.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Two shoppers do not see each other's saved products")
    func listsAreNotShared() async {
        let shopper = Saver(signedInAs: 1)
        await shopper.save(productId: 7)
        await shopper.writesToSettle()

        shopper.signIn(asUserId: 2)

        #expect(shopper.wishlist.isEmpty)

        shopper.signIn(asUserId: 1)
        #expect(shopper.wishlist.items.map(\.id) == [pid(7)])
    }

    @Test("Signing out leaves nothing of the shopper's list on screen")
    func signingOutClearsTheList() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)
        await shopper.writesToSettle()

        shopper.signOut()

        #expect(shopper.wishlist.isEmpty)
    }
}
