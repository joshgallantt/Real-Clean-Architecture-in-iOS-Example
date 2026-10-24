import Foundation
import Testing
@testable import Product

@Suite("SearchTerm")
struct SearchTermTests {
    @Test("An ordinary search is a search")
    func ordinary() {
        #expect(SearchTerm("lipstick")?.text == "lipstick")
    }

    @Test("Surrounding whitespace is not part of what was searched for")
    func trims() {
        #expect(SearchTerm("  lipstick  ")?.text == "lipstick")
    }

    @Test("Nothing typed is not a search")
    func empty() {
        #expect(SearchTerm("") == nil)
    }

    @Test("Whitespace alone is not a search")
    func whitespaceOnly() {
        #expect(SearchTerm("   ") == nil)
        #expect(SearchTerm("\n\t") == nil)
    }

    @Test("The same word in different case is the same search")
    func caseInsensitiveEquality() {
        #expect(SearchTerm("Lipstick") == SearchTerm("lipstick"))
        #expect(SearchTerm("LIPSTICK") == SearchTerm("lipstick"))
    }

    @Test("Two searches that differ by spacing alone are the same search")
    func whitespaceInsensitiveEquality() {
        #expect(SearchTerm(" lipstick") == SearchTerm("lipstick "))
    }

    @Test("Different words are different searches")
    func differentTerms() {
        #expect(SearchTerm("lipstick") != SearchTerm("mascara"))
    }

    @Test("Two searches that are equal hash alike, so a set keeps one")
    func hashing() {
        let terms = Set([SearchTerm("Lipstick"), SearchTerm("lipstick"), SearchTerm("mascara")])
        #expect(terms.count == 2)
    }
}
