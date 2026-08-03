import Foundation
import Testing
@testable import Session

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: written by programmers, for programmers,
/// naming the unit that broke. The acceptance suite says signing up was refused; these say which
/// rule refused it.
///
/// They are aimed at the value objects rather than at the use cases: a rule stated on a type is the
/// most stable seam a component has, so these survive the wiring above them being rearranged.
@Suite("Email")
struct EmailTests {
    @Test("An ordinary address is valid")
    func ordinary() {
        #expect(Email("ada@example.com").isValid)
    }

    @Test("Subdomains are fine")
    func subdomain() {
        #expect(Email("ada@mail.example.co.uk").isValid)
    }

    @Test("Empty is not an address")
    func empty() {
        #expect(Email("").isValid == false)
    }

    @Test("An address needs an @")
    func noAtSign() {
        #expect(Email("ada.example.com").isValid == false)
    }

    @Test("Two @s is not one address")
    func twoAtSigns() {
        #expect(Email("ada@@example.com").isValid == false)
        #expect(Email("a@b@example.com").isValid == false)
    }

    @Test("Something has to come before the @")
    func noLocalPart() {
        #expect(Email("@example.com").isValid == false)
    }

    @Test("Something has to come after it")
    func noDomain() {
        #expect(Email("ada@").isValid == false)
    }

    @Test("A domain needs a dot")
    func domainWithoutDot() {
        #expect(Email("ada@example").isValid == false)
    }

    @Test("A domain cannot start or end with a dot")
    func domainDotAtEdges() {
        #expect(Email("ada@.example.com").isValid == false)
        #expect(Email("ada@example.com.").isValid == false)
    }

    @Test("Two dots together is a typo, not a domain")
    func doubleDot() {
        #expect(Email("ada@example..com").isValid == false)
    }

    @Test("Whitespace anywhere makes it invalid")
    func whitespace() {
        #expect(Email("ada @example.com").isValid == false)
        #expect(Email(" ada@example.com").isValid == false)
        #expect(Email("ada@example.com ").isValid == false)
    }

    @Test("It keeps exactly what it was given, valid or not")
    func keepsItsValue() {
        #expect(Email("  Not An Address ").value == "  Not An Address ")
    }

    @Test("A half-typed address is representable, because a text field has to hold one")
    func halfTyped() {
        #expect(Email("ada@").value == "ada@")
    }

    @Test("Two addresses spelled the same are the same")
    func equality() {
        #expect(Email("ada@example.com") == Email("ada@example.com"))
        #expect(Email("ada@example.com") != Email("grace@example.com"))
    }
}

@Suite("Password")
struct PasswordTests {
    @Test("Long enough is valid")
    func longEnough() {
        #expect(Password("hunter2").isValid)
    }

    @Test("Exactly the minimum is long enough")
    func exactlyTheMinimum() {
        #expect(Password(String(repeating: "a", count: Password.minimumLength)).isValid)
    }

    @Test("One short is not")
    func oneShort() {
        #expect(Password(String(repeating: "a", count: Password.minimumLength - 1)).isValid == false)
    }

    @Test("Empty is not")
    func empty() {
        #expect(Password("").isValid == false)
    }

    @Test("Spaces count as characters — this rule is about length and nothing else")
    func spacesCount() {
        #expect(Password("    ").isValid)
    }
}

@Suite("PersonName")
struct PersonNameTests {
    @Test("A first name is enough")
    func firstOnly() {
        #expect(PersonName(first: "Ada", last: nil).isValid)
    }

    @Test("Plenty of people have one name, and the full name is just that")
    func fullOfFirstOnly() {
        #expect(PersonName(first: "Ada", last: nil).full == "Ada")
    }

    @Test("Both names are joined by a single space")
    func fullOfBoth() {
        #expect(PersonName(first: "Ada", last: "Lovelace").full == "Ada Lovelace")
    }

    @Test("A blank last name is no last name")
    func blankLastIsNil() {
        #expect(PersonName(first: "Ada", last: "   ").last == nil)
        #expect(PersonName(first: "Ada", last: "").last == nil)
    }

    @Test("Surrounding whitespace is not part of a name")
    func trimsForDisplay() {
        #expect(PersonName(first: "  Ada  ", last: "  Lovelace  ").full == "Ada Lovelace")
    }

    @Test("A blank first name is not a name")
    func blankFirstIsInvalid() {
        #expect(PersonName(first: "   ", last: "Lovelace").isValid == false)
        #expect(PersonName(first: "", last: nil).isValid == false)
    }
}

@Suite("Session")
struct SessionStateTests {
    private let ada = User(
        id: UserID(rawValue: 1),
        email: Email("ada@example.com"),
        name: PersonName(first: "Ada", last: nil)
    )

    @Test("A guest is not logged in and is nobody")
    func guest() {
        #expect(Session.guest.isLoggedIn == false)
        #expect(Session.guest.user == nil)
    }

    @Test("Being authenticated is being logged in, as somebody")
    func authenticated() {
        #expect(Session.authenticated(ada).isLoggedIn)
        #expect(Session.authenticated(ada).user == ada)
    }

    @Test("Two sessions for the same person are the same session")
    func equality() {
        #expect(Session.authenticated(ada) == Session.authenticated(ada))
        #expect(Session.authenticated(ada) != Session.guest)
    }
}

