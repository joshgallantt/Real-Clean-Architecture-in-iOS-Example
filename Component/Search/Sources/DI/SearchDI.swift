import Search
import SearchData
import Session

public struct SearchDI {
    public let getSearchHistoryUseCase: GetSearchHistoryUseCase
    public let recordSearchUseCase: RecordSearchUseCase
    public let clearSearchHistoryUseCase: ClearSearchHistoryUseCase

    public init(store: SearchHistoryStore, getSession: GetSessionUseCase) {
        let repository = DefaultSearchHistoryRepository(store: store, getSession: getSession)
        self.getSearchHistoryUseCase = DefaultGetSearchHistoryUseCase(searchHistoryRepository: repository)
        self.recordSearchUseCase = DefaultRecordSearchUseCase(searchHistoryRepository: repository)
        self.clearSearchHistoryUseCase = DefaultClearSearchHistoryUseCase(searchHistoryRepository: repository)
    }
}
