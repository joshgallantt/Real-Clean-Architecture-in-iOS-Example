import Foundation
import ProductTestSupport
import Testing
import Product
import Wishlist

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

        let returning = shopper.leaveAndComeBack()

        #expect(returning.wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Two shoppers do not see each other's saved products")
    func listsAreNotShared() async {
        let shopper = Saver(signedInAs: 1)
        await shopper.save(productId: 7)

        shopper.signIn(asUserId: 2)

        #expect(shopper.wishlist.isEmpty)

        shopper.signIn(asUserId: 1)
        #expect(shopper.wishlist.items.map(\.id) == [pid(7)])
    }

    @Test("Signing out leaves nothing of the shopper's list on screen")
    func signingOutClearsTheList() async {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)

        shopper.signOut()

        #expect(shopper.wishlist.isEmpty)
    }
}
