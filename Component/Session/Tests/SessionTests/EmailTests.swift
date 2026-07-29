import Testing
import Session

/// What the app is willing to treat as an email address. It can only ever guess — the
/// one way to know an address is real is to send something to it — so these pin down
/// what is obviously wrong, and leave the rest to the shop's confirmation.
@Suite("What counts as an email address")
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
        // Silently trimming would sign the shopper in under an address they did not
        // type, and they would never find out which one.
        #expect(!Email(" shopper@example.com").isValid)
        #expect(!Email("shopper@example.com ").isValid)
    }

    @Test("A half-typed address is representable, just not valid")
    func holdsWhateverItIsGiven() {
        // The text field binds to this, so it has to survive every keystroke on the way
        // to a real address.
        let halfway = Email("shopper@exa")

        #expect(halfway.value == "shopper@exa")
        #expect(!halfway.isValid)
    }
}
