// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Product
import SearchHistory

@MainActor
public final class StubGetSearchHistory: GetSearchHistoryUseCase, @unchecked Sendable {
    public init() {}

    public var history = SearchHistory()

    public func callAsFunction() -> SearchHistory { history }
}

@MainActor
public final class SpyRecordSearch: RecordSearchUseCase, @unchecked Sendable {
    public init() {}

    public private(set) var recorded: [SearchTerm] = []

    public func callAsFunction(_ term: SearchTerm) {
        recorded.append(term)
    }
}

@MainActor
public final class SpyClearSearchHistory: ClearSearchHistoryUseCase, @unchecked Sendable {
    public init() {}

    public private(set) var callCount = 0

    public func callAsFunction() {
        callCount += 1
    }
}
