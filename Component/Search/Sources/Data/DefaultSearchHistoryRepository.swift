import Foundation
import Search
import Session

public struct DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let store: SearchHistoryStore
    private let getSession: GetSessionUseCase
    private let maxRecentSearches = 10

    public init(store: SearchHistoryStore, getSession: GetSessionUseCase) {
        self.store = store
        self.getSession = getSession
    }

    private func userKey() async -> String {
        await getSession().user.map { String($0.id) } ?? "guest"
    }

    public func getRecentSearches() async -> [String] {
        store.getQueries(forUserKey: await userKey())
    }

    public func recordSearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = await userKey()
        var queries = store.getQueries(forUserKey: key)
        queries.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        queries.insert(trimmed, at: 0)
        store.setQueries(Array(queries.prefix(maxRecentSearches)), forUserKey: key)
    }

    public func clearRecentSearches() async {
        store.setQueries([], forUserKey: await userKey())
    }
}
