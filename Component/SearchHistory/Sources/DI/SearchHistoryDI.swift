import Combine
import SearchHistory
import SearchHistoryData
import Session

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct SearchHistoryDI {
    public let getSearchHistoryUseCase: GetSearchHistoryUseCase
    public let recordSearchUseCase: RecordSearchUseCase
    public let clearSearchHistoryUseCase: ClearSearchHistoryUseCase

    @MainActor
    public init(
        store: SearchHistoryStore,
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: the session reaches storage here, at the wiring
        /// boundary, and nowhere else decides whose data is live. What the repository receives is whose
        /// history it is keeping.
        let repository = DefaultSearchHistoryRepository(
            store: store,
            session: getSession(),
            sessionPublisher: observeSession()
                .removeDuplicates(by: { $0.user?.id == $1.user?.id })
                .eraseToAnyPublisher()
        )
        self.getSearchHistoryUseCase = DefaultGetSearchHistoryUseCase(repository: repository)
        self.recordSearchUseCase = DefaultRecordSearchUseCase(repository: repository)
        self.clearSearchHistoryUseCase = DefaultClearSearchHistoryUseCase(repository: repository)
    }
}
