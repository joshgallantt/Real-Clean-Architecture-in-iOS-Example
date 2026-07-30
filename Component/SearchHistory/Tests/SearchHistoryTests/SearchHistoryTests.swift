import Foundation
import Testing
import Product
import SearchHistory

@Suite("Remembering what a shopper searched for")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the domain is tested with no
/// repository, no store and no simulator in the room. Anything here that needed one would not be a
/// domain rule.
struct SearchHistoryTests {
    @Test("A new history remembers nothing")
    func empty() {
        #expect(SearchHistory().isEmpty)
    }

    @Test("A search is remembered, most recent first")
    func recordsMostRecentFirst() {
        let history = SearchHistory()
            .recording(term("mascara"))
            .recording(term("sofa"))

        #expect(history.terms.map(\.text) == ["sofa", "mascara"])
    }

    @Test("Searching for something again moves it back to the top rather than repeating it")
    func repeatedSearchMovesToTop() {
        let history = SearchHistory()
            .recording(term("mascara"))
            .recording(term("sofa"))
            .recording(term("mascara"))

        #expect(history.terms.map(\.text) == ["mascara", "sofa"])
    }

    @Test("Case is not what makes two searches different")
    func caseInsensitiveRepeat() {
        let history = SearchHistory()
            .recording(term("red dress"))
            .recording(term("Red Dress"))

        #expect(history.terms.map(\.text) == ["Red Dress"])
    }

    @Test("Only the last ten searches are worth keeping")
    func keepsOnlyTheLastTen() {
        let history = (1...15).reduce(SearchHistory()) { $0.recording(term("search \($1)")) }

        #expect(history.terms.count == SearchHistory.limit)
        #expect(history.terms.first?.text == "search 15")
        #expect(history.terms.last?.text == "search 6")
    }

    @Test("A history handed more than it can hold keeps the most recent")
    func trimsWhateverItIsGiven() {
        let tooMany = (1...15).map { term("search \($0)") }

        #expect(SearchHistory(terms: tooMany).terms == Array(tooMany.prefix(10)))
    }

    @Test("Clearing forgets everything")
    func clearing() {
        let history = SearchHistory().recording(term("mascara")).recording(term("sofa"))

        #expect(history.cleared().isEmpty)
    }
}

private func term(_ text: String) -> SearchTerm {
    SearchTerm(text)!
}
