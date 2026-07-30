import Foundation
import Testing
import StockAlert

@MainActor
@Suite("Being told when something is back")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct BeingToldWhenItIsBackTests {
    @Test("A shopper asks to be told about something, and the bell says they asked")
    func asksToBeTold() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.askToBeTold(aboutProductId: 1)

        #expect(shopper.bellIsRinging[pid(1)] == true)
    }

    @Test("A shopper who has asked about nothing is waiting on nothing")
    func nothingAskedYet() {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        #expect(shopper.bellIsRinging[pid(1)] == false)
    }

    @Test("Asking twice is one ask — nobody wants telling twice")
    func askingTwice() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.askToBeTold(aboutProductId: 1)
        await shopper.askToBeTold(aboutProductId: 1)

        #expect(shopper.bellIsRinging[pid(1)] == true)
    }

    @Test("A shopper who changes their mind stops being on the hook for it")
    func changesTheirMind() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.askToBeTold(aboutProductId: 1)

        await shopper.changeTheirMind(aboutProductId: 1)

        #expect(shopper.bellIsRinging[pid(1)] == false)
    }

    @Test("Changing their mind about something they never asked about changes nothing")
    func changingMindAboutNothing() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.askToBeTold(aboutProductId: 1)

        await shopper.changeTheirMind(aboutProductId: 99)

        #expect(shopper.bellIsRinging[pid(1)] == true)
    }

    @Test("The bell on one product ignores what the shopper asks about others")
    func theBellFollowsOneProduct() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 7)
        await shopper.askToBeTold(aboutProductId: 7)

        await shopper.askToBeTold(aboutProductId: 99)
        await shopper.changeTheirMind(aboutProductId: 99)

        #expect(shopper.bellIsRinging[pid(7)] == true)
    }

    @Test("What a shopper asked about is still asked about when they come back")
    func survivesLeaving() async {
        let shopper = Waiter(signedInAs: 42)
        await shopper.askToBeTold(aboutProductId: 1)

        let returning = shopper.leaveAndComeBack()
        returning.watchTheBell(onProductId: 1)

        #expect(returning.bellIsRinging[pid(1)] == true)
    }
}

@MainActor
@Suite("Somebody has to be told")
/// Being told when something returns needs somewhere to send it, and a guest has not said where.
/// The rule is met the way a shopper meets it — as an answer from what they tried, not a check
/// somebody had to remember to make first.
struct SomebodyHasToBeToldTests {
    @Test("A guest is asked to sign in rather than quietly promised nothing")
    func guestIsAskedToSignIn() async {
        let shopper = Waiter()

        #expect(await shopper.askToBeTold(aboutProductId: 1).failure == .unauthenticated)
    }

    @Test("A guest cannot change their mind either, having never been on the hook")
    func guestCannotChangeTheirMind() async {
        let shopper = Waiter()

        #expect(await shopper.changeTheirMind(aboutProductId: 1).failure == .unauthenticated)
    }

    @Test("Signing in after being asked, the shopper gets what they were after")
    func signingInThenAsking() async {
        let shopper = Waiter()
        #expect(await shopper.askToBeTold(aboutProductId: 1).failure == .unauthenticated)

        shopper.signIn(asUserId: 42)
        shopper.watchTheBell(onProductId: 1)

        #expect(await shopper.askToBeTold(aboutProductId: 1).failure == nil)
        #expect(shopper.bellIsRinging[pid(1)] == true)
    }

    @Test("Two shoppers are not waiting on each other's products")
    func alertsAreNotShared() async {
        let shopper = Waiter(signedInAs: 1)
        shopper.watchTheBell(onProductId: 7)
        await shopper.askToBeTold(aboutProductId: 7)

        shopper.signIn(asUserId: 2)

        #expect(shopper.bellIsRinging[pid(7)] == false)

        shopper.signIn(asUserId: 1)
        #expect(shopper.bellIsRinging[pid(7)] == true)
    }

    @Test("Signing out leaves nobody waiting on anything")
    func signingOutClearsThem() async {
        let shopper = Waiter(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.askToBeTold(aboutProductId: 1)

        shopper.signOut()

        #expect(shopper.bellIsRinging[pid(1)] == false)
    }
}

@MainActor
@Suite("When the ask cannot be kept")
struct WhenTheAskCannotBeKeptTests {
    @Test("An ask that could not be written down is reported, not quietly forgotten")
    func askingFails() async throws {
        let shopper = Waiter(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await shopper.askToBeTold(aboutProductId: 1).failure == .unavailable)
    }

    @Test("A bell does not ring for an ask nobody recorded")
    func theBellDoesNotPretend() async throws {
        let shopper = Waiter(in: try .unwritableDirectory(), signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.askToBeTold(aboutProductId: 1)

        #expect(shopper.bellIsRinging[pid(1)] == false)
    }

    @Test("Not being signed in and not being able to keep the ask are different answers")
    func differentAnswers() async throws {
        let guest = Waiter(in: try .unwritableDirectory())
        let shopper = Waiter(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await guest.askToBeTold(aboutProductId: 1).failure == .unauthenticated)
        #expect(await shopper.askToBeTold(aboutProductId: 1).failure == .unavailable)
    }
}
