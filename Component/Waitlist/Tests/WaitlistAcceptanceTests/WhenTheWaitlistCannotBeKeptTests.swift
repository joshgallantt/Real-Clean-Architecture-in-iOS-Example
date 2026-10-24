import Foundation
import ProductTestSupport
import Testing
import Waitlist

@MainActor
@Suite("When the waitlist cannot be kept")
struct WhenTheWaitlistCannotBeKeptTests {
    @Test("Joining that could not be written down is reported, not quietly forgotten")
    func joiningFails() async throws {
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await shopper.join(productId: 1).failure == .unavailable)
    }

    @Test("The bell does not light up for a place nobody recorded")
    func theBellDoesNotPretend() async throws {
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.join(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Not being signed in and not being able to keep the list are different answers")
    func differentAnswers() async throws {
        let guest = Shopper(in: try .unwritableDirectory())
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await guest.join(productId: 1).failure == .unauthenticated)
        #expect(await shopper.join(productId: 1).failure == .unavailable)
    }
}
