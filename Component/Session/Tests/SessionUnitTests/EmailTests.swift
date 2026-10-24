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
