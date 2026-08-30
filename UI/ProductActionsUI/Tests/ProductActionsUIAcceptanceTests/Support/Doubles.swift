import Combine
import Foundation
import Bag
import Money
import Product
import Session
import StockAlert
import AuthUI
import SnackbarUI
@testable import ProductActionsUI

@MainActor
final class RecordingSnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) { shown.append(snackbar) }
}

@MainActor
final class StubProductActionsNavigation: ProductActionsNavigation {
    private(set) var switchedToBagTab = false

    nonisolated func switchToBagTab() {
        MainActor.assumeIsolated { switchedToBagTab = true }
    }
}

// MARK: - Fixtures
