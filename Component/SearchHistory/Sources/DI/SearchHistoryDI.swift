import SearchHistory
import SearchHistoryData
import Session

public struct SearchHistoryDI {
    public let getSearchHistoryUseCase: GetSearchHistoryUseCase
    public let recordSearchUseCase: RecordSearchUseCase
    public let clearSearchHistoryUseCase: ClearSearchHistoryUseCase

    public init(store: SearchHistoryStore, getSession: GetSessionUseCase) {
        let repository = DefaultSearchHistoryRepository(store: store, getSession: getSession)
        self.getSearchHistoryUseCase = DefaultGetSearchHistoryUseCase(repository: repository)
        self.recordSearchUseCase = DefaultRecordSearchUseCase(repository: repository)
        self.clearSearchHistoryUseCase = DefaultClearSearchHistoryUseCase(repository: repository)
    }
}
