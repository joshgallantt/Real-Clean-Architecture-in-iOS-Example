import Foundation
import Testing
import Product
import SearchHistory

/// Which searches are worth remembering, asserted without a store, a session or a catalog.
/// None of them depend on where the list is kept.
///
/// What makes something a search, and what makes two searches the same search, is asserted
/// in `SearchTermTests` — the rule lives on the term now, so this suite cannot restate it
/// and cannot drift from it.
@Suite("Remembering what a shopper searched for")
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

        // The newer spelling is what the shopper just typed, so it is what is kept.
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
