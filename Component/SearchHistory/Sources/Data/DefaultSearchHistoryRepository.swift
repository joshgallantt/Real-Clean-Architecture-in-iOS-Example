import Combine
import Foundation
import Product
import SearchHistory
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes a session and a
/// stream of sessions, and reads only who is signed in. It needs to know whose history is live,
/// not to understand identity, so it compares ids — a changed profile is not a changed owner. The
/// same shape the bag's and the settings' take, because it is the same question.
public final class DefaultSearchHistoryRepository: SearchHistoryRepository {
    private let store: SearchHistoryStore
    private var session: Session
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: SearchHistoryStore,
        session: Session,
        sessionPublisher: AnyPublisher<Session, Never>
    ) {
        self.store = store
        self.session = session

        sessionPublisher
            .sink { [weak self] session in
                self?.session = session
            }
            .store(in: &cancellables)
    }

    public func history() -> SearchHistory {
        SearchHistory(terms: store.getQueries(for: session).compactMap(SearchTerm.init))
    }

    public func save(_ history: SearchHistory) {
        store.setQueries(history.terms.map(\.text), for: session)
    }
}
