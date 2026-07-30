import Combine
import Foundation
import Product
import SearchHistory
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose history is live, not to understand
/// identity — the same shape the bag's and the wishlist's take, because it is the same question.
public final class DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let store: SearchHistoryStore
    private var owner: Owner
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: SearchHistoryStore,
        owner: Owner,
        ownerPublisher: AnyPublisher<Owner, Never>
    ) {
        self.store = store
        self.owner = owner

        ownerPublisher
            .sink { [weak self] owner in
                self?.owner = owner
            }
            .store(in: &cancellables)
    }

    public func history() -> SearchHistory {
        SearchHistory(terms: store.getQueries(for: owner).compactMap(SearchTerm.init))
    }

    public func save(_ history: SearchHistory) {
        store.setQueries(history.terms.map(\.text), for: owner)
    }
}
