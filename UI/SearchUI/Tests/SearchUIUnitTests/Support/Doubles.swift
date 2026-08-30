import SnackbarUITestSupport
import Foundation
import Money
import Product
import SearchHistory
import SnackbarUI
@testable import SearchUI

@MainActor
final class StubGetSearchHistory: GetSearchHistoryUseCase, @unchecked Sendable {
    var history = SearchHistory()

    func callAsFunction() -> SearchHistory { history }
}

@MainActor
final class SpyClearSearchHistory: ClearSearchHistoryUseCase, @unchecked Sendable {
    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}

@MainActor
final class SpyRecordSearch: RecordSearchUseCase, @unchecked Sendable {
    private(set) var recorded: [SearchTerm] = []

    func callAsFunction(_ term: SearchTerm) {
        recorded.append(term)
    }
}

@MainActor
func waitUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<200 where !isSatisfied() {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures
