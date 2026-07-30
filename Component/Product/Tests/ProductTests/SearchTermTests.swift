import Foundation
import Testing
import Product

/// What makes something a search, and what makes two searches the same search. Stated once,
/// here, because every place that used to decide it for itself — a text field trimming
/// before it searched, a history list trimming again afterwards — could disagree with the
/// others and did.
@Suite("What counts as a search")
struct SearchTermTests {

    @Test("Ordinary words are a search")
    func acceptsWords() {
        #expect(SearchTerm("red dress")?.text == "red dress")
    }

    @Test("Nothing typed is not a search")
    func rejectsBlank() {
        #expect(SearchTerm("") == nil)
        #expect(SearchTerm("   ") == nil)
        #expect(SearchTerm("\n\t") == nil)
    }

    @Test("Surrounding whitespace is not part of what the shopper searched for")
    func trimsWhitespace() {
        #expect(SearchTerm("  red dress  ")?.text == "red dress")
        #expect(SearchTerm("\nsofa\t")?.text == "sofa")
    }

    @Test("Whitespace inside what they typed is theirs to keep")
    func keepsInnerWhitespace() {
        #expect(SearchTerm("red  dress")?.text == "red  dress")
    }

    @Test("Case is not what makes two searches different")
    func caseDoesNotMakeADifference() {
        #expect(SearchTerm("red dress") == SearchTerm("Red Dress"))
        #expect(SearchTerm("SOFA") == SearchTerm("sofa"))
    }

    @Test("Neither is the whitespace that was trimmed off")
    func trimmedWhitespaceDoesNotMakeADifference() {
        #expect(SearchTerm("  sofa") == SearchTerm("sofa  "))
    }

    @Test("Two searches for the same words land in the same place in a set")
    func hashesConsistentlyWithEquality() {
        let terms = Set([SearchTerm("sofa")!, SearchTerm("SOFA")!, SearchTerm("  sofa ")!])

        #expect(terms.count == 1)
    }

    @Test("Different words are different searches")
    func differentWords() {
        #expect(SearchTerm("sofa") != SearchTerm("sofas"))
    }

    @Test("The shopper's own capitalisation is what they see back")
    func keepsTheirSpelling() {
        // Two terms can be equal and still not be the same text: what is kept is what they
        // typed, so their history reads the way they wrote it.
        #expect(SearchTerm("Red Dress")?.text == "Red Dress")
    }
}
