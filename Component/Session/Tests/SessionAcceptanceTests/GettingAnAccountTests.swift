import Foundation
import Testing
import Session

@MainActor
@Suite("Getting an account")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct GettingAnAccountTests {
    @Test("A shopper signs up and is signed in straight away, without signing in again")
    func signsUp() async {
        let shopper = Account()

        await shopper.createAccount()

        #expect(shopper.isSignedIn)
        #expect(shopper.nameOnScreen == "Ada Lovelace")
    }

    @Test("Plenty of people have one name, and the shop takes them as they are")
    func oneName() async {
        let shopper = Account()

        let outcome = await shopper.createAccount(firstName: "Prince", lastName: nil)

        #expect(outcome.failure == nil)
        #expect(shopper.nameOnScreen == "Prince")
    }

    @Test("A last name left blank is absence, not an empty one trailing the shopper around")
    func blankLastName() async {
        let shopper = Account()

        await shopper.createAccount(firstName: "Prince", lastName: "   ")

        #expect(shopper.nameOnScreen == "Prince")
    }

    @Test("A shopper who gives no first name is asked for one")
    func noFirstName() async {
        let shopper = Account()

        #expect(await shopper.createAccount(firstName: " ").failure == .nameIsMissing)
        #expect(!shopper.isSignedIn)
    }

    @Test(
        "Something that is not an address is refused, and the shopper is told which thing is wrong",
        arguments: ["", "ada", "ada@", "@example.com", "ada@example", "ada @example.com", "ada@example..com"]
    )
    func notAnAddress(_ typed: String) async {
        let shopper = Account()

        #expect(await shopper.createAccount(email: typed).failure == .invalidEmail)
    }

    @Test("An ordinary address is accepted", arguments: ["ada@example.com", "ada.b+tag@sub.example.co.uk"])
    func ordinaryAddress(_ typed: String) async {
        let shopper = Account()

        #expect(await shopper.createAccount(email: typed).failure == nil)
    }

    @Test("A password too short to be one is refused")
    func shortPassword() async {
        let shopper = Account()

        #expect(await shopper.createAccount(password: "abc").failure == .invalidPassword)
    }

    @Test("A passphrase is a password — spaces are the shopper's business")
    func passphrase() async {
        let shopper = Account()

        #expect(await shopper.createAccount(password: "correct horse battery").failure == nil)
    }

    @Test("A shopper is told one thing at a time, starting with their name")
    func oneThingAtATime() async {
        let shopper = Account()

        let everythingWrong = await shopper.createAccount(firstName: "", email: "nope", password: "x")

        #expect(everythingWrong.failure == .nameIsMissing)

        let nameFixed = await shopper.createAccount(email: "nope", password: "x")
        #expect(nameFixed.failure == .invalidEmail)

        let emailFixed = await shopper.createAccount(password: "x")
        #expect(emailFixed.failure == .invalidPassword)
    }

    @Test("Signing up with an address that already has an account is said plainly")
    func addressAlreadyUsed() async {
        let shopper = Account()
        await shopper.createAccount(email: "ada@example.com")

        let again = await shopper.leaveAndComeBack().createAccount(email: "ada@example.com")

        #expect(again.failure == .emailAlreadyInUse)
    }
}

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
