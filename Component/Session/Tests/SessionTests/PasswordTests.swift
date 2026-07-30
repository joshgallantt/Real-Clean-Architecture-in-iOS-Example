import Testing
import Session

@Suite("What counts as a password")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the domain is tested with no
/// repository, no store and no simulator in the room. Anything here that needed one would not be a
/// domain rule.
struct PasswordTests {

    @Test("Long enough is the only rule, and it is stated once")
    func acceptsLongEnough() {
        #expect(Password(String(repeating: "a", count: Password.minimumLength)).isValid)
        #expect(Password("correct horse battery staple").isValid)
    }

    @Test("Too short is refused here rather than by the shop")
    func rejectsTooShort() {
        #expect(!Password(String(repeating: "a", count: Password.minimumLength - 1)).isValid)
        #expect(!Password("").isValid)
    }

    @Test("Spaces count — a passphrase is a password")
    func spacesCount() {
        #expect(Password("a b c d ").isValid)
    }

    @Test("A half-typed password is representable, just not valid")
    func holdsWhateverItIsGiven() {
        let halfway = Password("abc")

        #expect(halfway.value == "abc")
        #expect(!halfway.isValid)
    }
}
