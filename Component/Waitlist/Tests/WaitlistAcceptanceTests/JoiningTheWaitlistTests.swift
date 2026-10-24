import Foundation
import ProductTestSupport
import Testing
import Waitlist

@MainActor
@Suite("Joining the waitlist")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct JoiningTheWaitlistTests {
    @Test("A shopper joins the waitlist for something, and the bell says they did")
    func joins() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.join(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == true)
    }

    @Test("A shopper who has joined nothing is waiting on nothing")
    func nothingJoinedYet() {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Joining twice is one place on the list — nobody wants telling twice")
    func joiningTwice() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.join(productId: 1)
        await shopper.join(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == true)
        #expect(shopper.waitlist.itemCount == 1)
    }

    @Test("A shopper who leaves the waitlist is no longer on it")
    func leaves() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.join(productId: 1)

        await shopper.leave(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Leaving something they never joined changes nothing, and is not an error")
    func leavingWhatTheyNeverJoined() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.join(productId: 1)

        #expect(await shopper.leave(productId: 99).failure == nil)
        #expect(shopper.bellIsOn[pid(1)] == true)
    }

    @Test("The bell on one product ignores what the shopper does with others")
    func theBellFollowsOneProduct() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 7)
        await shopper.join(productId: 7)

        await shopper.join(productId: 99)
        await shopper.leave(productId: 99)

        #expect(shopper.bellIsOn[pid(7)] == true)
    }

    @Test("The waitlist is still there when the shopper comes back")
    func survivesLeaving() async {
        let shopper = Shopper(signedInAs: 42)
        await shopper.join(productId: 1)

        let returning = shopper.leaveAndComeBack()
        returning.watchTheBell(onProductId: 1)

        #expect(returning.bellIsOn[pid(1)] == true)
    }

    @Test("A waitlist kept before the rename is carried forward, and only once")
    func carriesTheOldListForward() async throws {
        let legacy = URL.newTemporaryDirectory
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data(#"[{"productId":1,"dateAsked":0}]"#.utf8).write(to: legacy.appending(path: "42.json"))

        let shopper = Shopper(legacyDirectory: legacy, signedInAs: 42)

        #expect(shopper.waitlist.contains(productId: pid(1)))
        #expect(!FileManager.default.fileExists(atPath: legacy.appending(path: "42.json").path()))
        #expect(shopper.leaveAndComeBack().waitlist.contains(productId: pid(1)))
    }
}
