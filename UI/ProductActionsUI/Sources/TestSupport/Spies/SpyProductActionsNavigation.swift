import SnackbarUITestSupport
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
