import Testing
import Session

@Suite("What counts as an email address")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the domain is tested with no
/// repository, no store and no simulator in the room. Anything here that needed one would not be a
/// domain rule.
struct EmailTests {
    @Test("An ordinary address is fine", arguments: [
        "shopper@example.com",
        "first.last@example.co.uk",
        "shopper+offers@example.com",
        "s@e.io"
    ])
    func accepts(address: String) {
        #expect(Email(address).isValid)
    }

    @Test("Nothing typed yet is not an address")
    func rejectsEmpty() {
        #expect(!Email("").isValid)
        #expect(!Email("   ").isValid)
    }

    @Test("Something that is not an address is not an address", arguments: [
        "shopper",
        "shopper@",
        "@example.com",
        "shopper@example",
        "shopper@@example.com",
        "shopper@.com",
        "shopper@example.",
        "shopper@exa..mple.com"
    ])
    func rejects(notAnAddress: String) {
        #expect(!Email(notAnAddress).isValid)
    }

    @Test("Stray whitespace is rejected rather than quietly trimmed")
    func rejectsSurroundingWhitespace() {
        #expect(!Email(" shopper@example.com").isValid)
        #expect(!Email("shopper@example.com ").isValid)
    }

    @Test("A half-typed address is representable, just not valid")
    func holdsWhateverItIsGiven() {
        let halfway = Email("shopper@exa")

        #expect(halfway.value == "shopper@exa")
        #expect(!halfway.isValid)
    }
}
