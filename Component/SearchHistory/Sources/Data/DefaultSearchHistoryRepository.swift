import Foundation
import Product
import SearchHistory
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

    /// A stored string that is no longer a search — blank, or whitespace left by an older
    /// build — is dropped rather than carried inward. `SearchTerm` is the one place that
    /// decides, and this is where storage has to pass through it.
    public func history() async -> SearchHistory {
        SearchHistory(terms: store.getQueries(forUserKey: await userKey()).compactMap(SearchTerm.init))
    }

    public func save(_ history: SearchHistory) async {
        store.setQueries(history.terms.map(\.text), forUserKey: await userKey())
    }

    /// Exhaustive over `Session` rather than reading `session.user`, so a new kind of session
    /// has to be a decision about whose searches these are.
    ///
    /// Unlike a wishlist, a guest does have a history — searching needs no account — so being
    /// nobody in particular is a key of its own rather than nothing to write.
    private func userKey() async -> String {
        switch await getSession() {
        case .guest:
            "guest"
        case .authenticated(let user):
            String(user.id.rawValue)
        }
    }
}
