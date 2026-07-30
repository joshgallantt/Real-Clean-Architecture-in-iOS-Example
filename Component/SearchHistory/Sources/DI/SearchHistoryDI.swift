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
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once, at the wiring boundary. What the repository receives is whose
        /// history it is keeping.
        let repository = DefaultSearchHistoryRepository(
            store: store,
            owner: Owner(getSession()),
            ownerPublisher: observeSession()
                .map(Owner.init)
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.getSearchHistoryUseCase = DefaultGetSearchHistoryUseCase(repository: repository)
        self.recordSearchUseCase = DefaultRecordSearchUseCase(repository: repository)
        self.clearSearchHistoryUseCase = DefaultClearSearchHistoryUseCase(repository: repository)
    }
}
