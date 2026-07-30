import Foundation
import Testing
import Product
import SearchHistory
import SearchHistoryData
import SearchHistoryDI
import Session

@Suite("Coming back to a search")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. What no layer test
/// can show is that the layers fit together.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct SearchingAgainTests {
    @Test("A shopper's recent searches are waiting for them, most recent first")
    func recentSearchesAreRemembered() async {
        let shopper = Searcher()

        await shopper.search(for: "mascara")
        await shopper.search(for: "red dress")

        #expect(await shopper.recentSearches == ["red dress", "mascara"])
    }

    @Test("Running the same search again moves it back to the top rather than repeating it")
    func repeatedSearch() async {
        let shopper = Searcher()

        await shopper.search(for: "mascara")
        await shopper.search(for: "sofa")
        await shopper.search(for: "MASCARA")

        #expect(await shopper.recentSearches == ["MASCARA", "sofa"])
    }

    @Test("Tapping search with nothing typed leaves the list alone")
    func blankSearch() async {
        let shopper = Searcher()
        await shopper.search(for: "mascara")

        await shopper.search(for: "  ")

        #expect(await shopper.recentSearches == ["mascara"])
    }

    @Test("Only the last ten are kept, however many a shopper runs")
    func onlyTheLastTen() async {
        let shopper = Searcher()

        for i in 1...15 {
            await shopper.search(for: "search \(i)")
        }

        let recent = await shopper.recentSearches
        #expect(recent.count == 10)
        #expect(recent.first == "search 15")
    }

    @Test("Clearing forgets everything, and the next search starts a fresh list")
    func clearing() async {
        let shopper = Searcher()
        await shopper.search(for: "mascara")

        await shopper.clearHistory()

        #expect(await shopper.recentSearches.isEmpty)

        await shopper.search(for: "sofa")
        #expect(await shopper.recentSearches == ["sofa"])
    }

    @Test("Two shoppers do not see each other's searches")
    func searchesAreNotShared() async {
        let store = InMemorySearchHistoryStore()
        let guest = Searcher(store: store)
        await guest.search(for: "mascara")

        let signedIn = Searcher(store: store, signedInAs: 42)
        await signedIn.search(for: "sofa")

        #expect(await guest.recentSearches == ["mascara"])
        #expect(await signedIn.recentSearches == ["sofa"])
    }
}

struct Searcher {
    private let di: SearchHistoryDI

    init(store: SearchHistoryStore = InMemorySearchHistoryStore(), signedInAs userId: Int? = nil) {
        self.di = SearchHistoryDI(store: store, getSession: StubGetSession(userId: userId))
    }

    var recentSearches: [String] {
        get async { await di.getSearchHistoryUseCase().terms.map(\.text) }
    }

    func search(for typed: String) async {
        guard let term = SearchTerm(typed) else { return }
        await di.recordSearchUseCase(term)
    }

    func clearHistory() async {
        await di.clearSearchHistoryUseCase()
    }
}

private struct StubGetSession: GetSessionUseCase {
    let userId: Int?

    @MainActor
    func callAsFunction() -> Session {
        guard let userId else { return .guest }
        return .authenticated(
            User(
                id: UserID(rawValue: userId),
                email: Email("shopper@example.com"),
                name: PersonName(first: "Ada", last: nil)
            )
        )
    }
}

final class InMemorySearchHistoryStore: SearchHistoryStore, @unchecked Sendable {
    private let lock = NSLock()
    private var queries: [String: [String]] = [:]

    func getQueries(forUserKey userKey: String) -> [String] {
        lock.withLock { queries[userKey] ?? [] }
    }

    func setQueries(_ queries: [String], forUserKey userKey: String) {
        lock.withLock { self.queries[userKey] = queries }
    }
}
