import Foundation
import Testing
import Session

@MainActor
@Suite("Staying signed in")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: how long a shopper stays signed in
/// is something they experience between one launch and the next, so it is asserted between one
/// launch and the next rather than by reading a token.
struct StayingSignedInTests {
    @Test("A shopper who has never signed in is a guest")
    func neverSignedIn() {
        #expect(!Account().isSignedIn)
    }

    @Test("A shopper who signed in is still signed in the next time they open the app")
    func survivesRelaunch() async {
        let shopper = Account()
        await shopper.createAccount()

        let returning = shopper.leaveAndComeBack()

        #expect(returning.isSignedIn)
        #expect(returning.nameOnScreen == "Ada Lovelace")
    }

    @Test("A shopper away longer than they stay signed in comes back a guest")
    func signInExpires() async {
        let shopper = Account(staysSignedInFor: .alreadyOver)
        await shopper.createAccount()

        let returning = shopper.leaveAndComeBack()

        #expect(!returning.isSignedIn)
    }

    @Test("An expired sign-in is forgotten, not left on the device to be tried again")
    func expiredSignInIsForgotten() async {
        let shopper = Account(staysSignedInFor: .alreadyOver)
        await shopper.createAccount()

        _ = shopper.leaveAndComeBack()

        #expect(!shopper.leaveAndComeBack().isSignedIn)
    }

    @Test("Signing out makes them a guest at once, and still a guest next launch")
    func signingOut() async {
        let shopper = Account()
        await shopper.createAccount()

        await shopper.logOut()

        #expect(!shopper.isSignedIn)
        #expect(!shopper.leaveAndComeBack().isSignedIn)
    }

    @Test("Signing in as somebody else replaces the shopper rather than adding one")
    func signingInAsSomebodyElse() async {
        let shopper = Account()
        await shopper.createAccount(firstName: "Ada", email: "ada@example.com", password: "hunter2")
        await shopper.logOut()
        await shopper.createAccount(firstName: "Grace", email: "grace@example.com", password: "hunter2")

        await shopper.logOut()
        await shopper.logIn(email: "ada@example.com", password: "hunter2")

        #expect(shopper.nameOnScreen == "Ada Lovelace")

        await shopper.logIn(email: "grace@example.com", password: "hunter2")
        #expect(shopper.nameOnScreen == "Grace Lovelace")
    }

    @Test("The same shopper is the same shopper on every device they sign in on")
    func sameShopperEveryTime() async {
        let firstDevice = Account()
        await firstDevice.createAccount(email: "ada@example.com")
        let idHere = firstDevice.session.user?.id

        let secondDevice = firstDevice.leaveAndComeBack()
        await secondDevice.logOut()
        await secondDevice.logIn(email: "ada@example.com")

        #expect(secondDevice.session.user?.id == idHere)
    }
}
