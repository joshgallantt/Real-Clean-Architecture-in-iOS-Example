import Foundation
import Product
import SearchHistory
import Session

/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
public struct DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let store: SearchHistoryStore
    private let getSession: GetSessionUseCase

    public init(store: SearchHistoryStore, getSession: GetSessionUseCase) {
        self.store = store
        self.getSession = getSession
    }

    public func history() async -> SearchHistory {
        SearchHistory(terms: store.getQueries(forUserKey: await userKey()).compactMap(SearchTerm.init))
    }

    public func save(_ history: SearchHistory) async {
        store.setQueries(history.terms.map(\.text), forUserKey: await userKey())
    }

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session`. Unlike a
    /// wishlist, a guest does have a history — searching needs no account — so being nobody in
    /// particular is a key of its own.
    private func userKey() async -> String {
        switch await getSession() {
        case .guest:
            "guest"
        case .authenticated(let user):
            String(user.id.rawValue)
        }
    }
}
