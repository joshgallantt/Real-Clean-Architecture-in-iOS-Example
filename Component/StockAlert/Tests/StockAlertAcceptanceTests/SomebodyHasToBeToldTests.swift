import Foundation
import ProductTestSupport
import Testing
import StockAlert

@MainActor
@Suite("Somebody has to be told")
/// Being told when something returns needs somewhere to send it, and a guest has not said where.
/// The rule is met the way a shopper meets it — as an answer from what they tried, not a check
/// somebody had to remember to make first.
struct SomebodyHasToBeToldTests {
    @Test("A guest is asked to sign in rather than quietly promised nothing")
    func guestIsAskedToSignIn() async {
        let shopper = Shopper()

        #expect(await shopper.setAlert(productId: 1).failure == .unauthenticated)
    }

    @Test("A guest cannot turn an alert off either, having never set one")
    func guestCannotTurnOneOff() async {
        let shopper = Shopper()

        #expect(await shopper.clearAlert(productId: 1).failure == .unauthenticated)
    }

    @Test("Signing in after being asked, the shopper gets what they were after")
    func signingInThenAsking() async {
        let shopper = Shopper()
        #expect(await shopper.setAlert(productId: 1).failure == .unauthenticated)

        shopper.signIn(asUserId: 42)
        shopper.watchTheBell(onProductId: 1)

        #expect(await shopper.setAlert(productId: 1).failure == nil)
        #expect(shopper.bellIsOn[pid(1)] == true)
    }

    @Test("Two shoppers do not have each other's alerts")
    func alertsAreNotShared() async {
        let shopper = Shopper(signedInAs: 1)
        shopper.watchTheBell(onProductId: 7)
        await shopper.setAlert(productId: 7)

        shopper.signIn(asUserId: 2)

        #expect(shopper.bellIsOn[pid(7)] == false)

        shopper.signIn(asUserId: 1)
        #expect(shopper.bellIsOn[pid(7)] == true)
    }

    @Test("Signing out leaves nobody waiting on anything")
    func signingOutClearsIt() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.setAlert(productId: 1)

        shopper.signOut()

        #expect(shopper.bellIsOn[pid(1)] == false)
    }
}
