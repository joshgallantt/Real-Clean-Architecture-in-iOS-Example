import Foundation
import Testing
import Session

@MainActor
@Suite("Signing in")
struct SigningInTests {
    @Test("A shopper signs in with the account they made")
    func signsIn() async {
        let shopper = Account()
        await shopper.createAccount(email: "ada@example.com", password: "hunter2")
        await shopper.logOut()

        await shopper.logIn(email: "ada@example.com", password: "hunter2")

        #expect(shopper.isSignedIn)
        #expect(shopper.nameOnScreen == "Ada Lovelace")
    }

    @Test("The wrong password does not sign anybody in")
    func wrongPassword() async {
        let shopper = Account()
        await shopper.createAccount(email: "ada@example.com", password: "hunter2")
        await shopper.logOut()

        let outcome = await shopper.logIn(email: "ada@example.com", password: "hunter3")

        #expect(outcome.failure == .invalidCredentials)
        #expect(!shopper.isSignedIn)
    }

    @Test("An address with no account behind it does not sign anybody in")
    func unknownAddress() async {
        let shopper = Account()

        let outcome = await shopper.logIn(email: "nobody@example.com", password: "hunter2")

        #expect(outcome.failure == .invalidCredentials)
        #expect(!shopper.isSignedIn)
    }

    @Test("A shopper still mid-way through typing is told what is wrong, not refused by the shop")
    func halfTyped() async {
        let shopper = Account()

        #expect(await shopper.logIn(email: "ada@").failure == .invalidEmail)
        #expect(await shopper.logIn(password: "abc").failure == .invalidPassword)
    }

    @Test("The address is checked before the password, so the shopper fixes one thing at a time")
    func addressFirst() async {
        let shopper = Account()

        #expect(await shopper.logIn(email: "nope", password: "x").failure == .invalidEmail)
    }
}
