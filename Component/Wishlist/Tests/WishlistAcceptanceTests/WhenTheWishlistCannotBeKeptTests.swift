import Foundation
import ProductTestSupport
import Testing
import Product
import Wishlist

@MainActor
@Suite("When the wishlist cannot be kept")
/// The shopper is not told which layer failed, because they cannot act on that. They are told the
/// change did not happen, which they can.
struct WhenTheWishlistCannotBeKeptTests {
    @Test("A save that could not be kept is reported, not quietly forgotten")
    func savingFails() async throws {
        let shopper = Saver(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await shopper.save(productId: 1).failure == .unavailable)
    }

    @Test("A list that could not be saved does not appear as though it was")
    func theListDoesNotPretend() async throws {
        let shopper = Saver(in: try .unwritableDirectory(), signedInAs: 42)
        shopper.watchTheHeart(onProductId: 1)

        await shopper.save(productId: 1)

        #expect(shopper.wishlist.isEmpty)
        #expect(shopper.heartIsFilled[pid(1)] == false)
    }

    @Test("Removing something that cannot be kept leaves it where it was")
    func removingFails() async throws {
        let shopper = Saver(signedInAs: 42)
        await shopper.save(productId: 1)

        let unlucky = Saver(in: try .unwritableDirectory(), signedInAs: 42)
        await unlucky.save(productId: 2)

        #expect(await unlucky.unsave(productId: 2).failure == .unavailable)
    }

    @Test("Not being signed in and not being able to save are different answers")
    func differentAnswers() async throws {
        let guest = Saver(in: try .unwritableDirectory())
        let shopper = Saver(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await guest.save(productId: 1).failure == .unauthenticated)
        #expect(await shopper.save(productId: 1).failure == .unavailable)
    }
}
