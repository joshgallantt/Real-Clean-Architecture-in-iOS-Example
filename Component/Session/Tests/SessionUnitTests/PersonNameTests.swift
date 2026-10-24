import Foundation
import Testing
@testable import Session

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
