import SnackbarUITestSupport
import Foundation
import Money
import Product
import SearchHistory
import SnackbarUI
@testable import SearchUI

@MainActor
func waitUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<200 where !isSatisfied() {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - Fixtures
