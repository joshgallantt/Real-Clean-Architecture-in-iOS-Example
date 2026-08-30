import Product
import SearchHistory

@MainActor
public final class StubGetSearchHistory: GetSearchHistoryUseCase {
    public init() {}

    public var history = SearchHistory()

    public func callAsFunction() -> SearchHistory { history }
}
