import Foundation
import Testing
import Search
import SearchData
import SearchDI
import Session

/// Journeys through the whole feature — use cases, repository and store — as the
/// composition root wires it.
@Suite("Coming back to a search")
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

/// The search feature wired as the composition root wires it, over an in-memory store.
struct Searcher {
    private let di: SearchDI

    init(store: SearchHistoryStore = InMemorySearchHistoryStore(), signedInAs userId: Int? = nil) {
        self.di = SearchDI(store: store, getSession: StubGetSession(userId: userId))
    }

    var recentSearches: [String] {
        get async { await di.getSearchHistoryUseCase().queries }
    }

    func search(for query: String) async {
        await di.recordSearchUseCase(query)
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
        return .authenticated(User(id: userId, email: "", firstName: "", lastName: ""))
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
