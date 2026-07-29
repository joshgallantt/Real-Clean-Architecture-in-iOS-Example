import Foundation
import Testing
import Search

/// Every rule about which searches are worth remembering, asserted without a store, a
/// session or a catalog. None of them depend on where the list is kept.
@Suite("Remembering what a shopper searched for")
struct SearchHistoryTests {

    @Test("A new history remembers nothing")
    func empty() {
        #expect(SearchHistory().isEmpty)
    }

    @Test("A search is remembered, most recent first")
    func recordsMostRecentFirst() {
        let history = SearchHistory()
            .recording("mascara")
            .recording("sofa")

        #expect(history.queries == ["sofa", "mascara"])
    }

    @Test("Blank is not a search")
    func ignoresBlank() {
        let history = SearchHistory().recording("mascara")

        #expect(history.recording("") == history)
        #expect(history.recording("   ") == history)
        #expect(history.recording("\n\t") == history)
    }

    @Test("Surrounding whitespace is not part of what the shopper searched for")
    func trimsWhitespace() {
        let history = SearchHistory().recording("  red dress  ")

        #expect(history.queries == ["red dress"])
    }

    @Test("Searching for something again moves it back to the top rather than repeating it")
    func repeatedSearchMovesToTop() {
        let history = SearchHistory()
            .recording("mascara")
            .recording("sofa")
            .recording("mascara")

        #expect(history.queries == ["mascara", "sofa"])
    }

    @Test("Case is not what makes two searches different")
    func caseInsensitiveRepeat() {
        let history = SearchHistory()
            .recording("red dress")
            .recording("Red Dress")

        // The newer spelling is what the shopper just typed, so it is what is kept.
        #expect(history.queries == ["Red Dress"])
    }

    @Test("Only the last ten searches are worth keeping")
    func keepsOnlyTheLastTen() {
        let history = (1...15).reduce(SearchHistory()) { $0.recording("search \($1)") }

        #expect(history.queries.count == SearchHistory.limit)
        #expect(history.queries.first == "search 15")
        #expect(history.queries.last == "search 6")
    }

    @Test("A history handed more than it can hold keeps the most recent")
    func trimsWhateverItIsGiven() {
        let tooMany = (1...15).map { "search \($0)" }

        #expect(SearchHistory(queries: tooMany).queries == Array(tooMany.prefix(10)))
    }

    @Test("Clearing forgets everything")
    func clearing() {
        let history = SearchHistory().recording("mascara").recording("sofa")

        #expect(history.cleared().isEmpty)
    }
}
