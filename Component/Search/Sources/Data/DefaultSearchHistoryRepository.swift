import Foundation
import Search
import Session

/// Reads and writes the signed-in shopper's searches. It decides nothing about which
/// searches are worth keeping.
public struct DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let store: SearchHistoryStore
    private let getSession: GetSessionUseCase

    public init(store: SearchHistoryStore, getSession: GetSessionUseCase) {
        self.store = store
        self.getSession = getSession
    }

    public func history() async -> SearchHistory {
        SearchHistory(queries: store.getQueries(forUserKey: await userKey()))
    }

    public func save(_ history: SearchHistory) async {
        store.setQueries(history.queries, forUserKey: await userKey())
    }

    private func userKey() async -> String {
        await getSession().user.map { String($0.id) } ?? "guest"
    }
}
