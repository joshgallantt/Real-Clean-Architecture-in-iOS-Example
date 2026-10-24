import Foundation
import ProductTestSupport
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
