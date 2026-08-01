import Foundation
import Testing
import Product
@testable import SearchHistory

@MainActor
/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: what "lately" means, stated as rules rather
/// than as a journey. The acceptance suite says a shopper saw their recent searches; these say which
/// rule decided the order and the length.
@Suite("SearchHistory")
struct SearchHistoryTests {
    private func term(_ text: String) -> SearchTerm { SearchTerm(text)! }

    @Test("A new history is empty")
    func empty() {
        #expect(SearchHistory().isEmpty)
        #expect(SearchHistory().terms.isEmpty)
    }

    @Test("Recording a search puts it in the history")
    func recording() {
        #expect(SearchHistory().recording(term("lipstick")).terms == [term("lipstick")])
    }

    @Test("The newest search comes first")
    func newestFirst() {
        let history = SearchHistory()
            .recording(term("lipstick"))
            .recording(term("mascara"))

        #expect(history.terms == [term("mascara"), term("lipstick")])
    }

    @Test("Searching the same thing again moves it up rather than repeating it")
    func repeatMovesToTop() {
        let history = SearchHistory()
            .recording(term("lipstick"))
            .recording(term("mascara"))
            .recording(term("lipstick"))

        #expect(history.terms == [term("lipstick"), term("mascara")])
    }

    @Test("The same search in different case is the same search, and does not repeat")
    func repeatIsCaseInsensitive() {
        let history = SearchHistory()
            .recording(term("lipstick"))
            .recording(term("LIPSTICK"))

        #expect(history.terms.count == 1)
    }

    @Test("Only the last handful are kept")
    func keepsOnlyTheLimit() {
        var history = SearchHistory()
        for i in 1...(SearchHistory.limit + 5) {
            history = history.recording(term("search \(i)"))
        }

        #expect(history.terms.count == SearchHistory.limit)
    }

    @Test("It is the oldest that falls off the end")
    func oldestFallsOff() {
        var history = SearchHistory()
        for i in 1...(SearchHistory.limit + 1) {
            history = history.recording(term("search \(i)"))
        }

        #expect(history.terms.first == term("search \(SearchHistory.limit + 1)"))
        #expect(history.terms.contains(term("search 1")) == false)
    }

    @Test("Building one from too many keeps only the limit")
    func initialiserEnforcesTheLimit() {
        let tooMany = (1...(SearchHistory.limit + 4)).map { term("search \($0)") }

        #expect(SearchHistory(terms: tooMany).terms.count == SearchHistory.limit)
    }

    @Test("Clearing leaves nothing")
    func cleared() {
        let history = SearchHistory().recording(term("lipstick")).cleared()

        #expect(history.isEmpty)
    }

    @Test("Clearing an empty history is no different")
    func clearingNothing() {
        #expect(SearchHistory().cleared().isEmpty)
    }

    @Test("Recording never changes the history it was asked of")
    func sideEffectFree() {
        let before = SearchHistory().recording(term("lipstick"))
        _ = before.recording(term("mascara"))

        #expect(before.terms == [term("lipstick")])
    }

    @Test("Two histories with the same searches in the same order are the same")
    func equality() {
        #expect(SearchHistory().recording(term("a")) == SearchHistory().recording(term("a")))
        #expect(SearchHistory().recording(term("a")) != SearchHistory().recording(term("b")))
    }
}
