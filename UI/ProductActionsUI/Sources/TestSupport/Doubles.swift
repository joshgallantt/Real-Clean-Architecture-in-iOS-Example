// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import SnackbarUITestSupport
import Combine
import Foundation
import Bag
import Money
import Product
import StockAlert
import Wishlist
import AuthUI
import SnackbarUI
@testable import ProductActionsUI

@MainActor
final class SpyProductActionsNavigation: ProductActionsNavigation {
    private(set) var switchedToBagTab = false

    nonisolated func switchToBagTab() {
        MainActor.assumeIsolated { switchedToBagTab = true }
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures
