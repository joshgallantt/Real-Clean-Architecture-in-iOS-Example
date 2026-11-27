import Product
@testable import StockAlertUI

@MainActor
final class SpyStockAlertNavigation: StockAlertNavigation {
    private(set) var openedProducts: [Product] = []
    private(set) var openedAllStockAlerts = 0

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product) }
    }

    nonisolated func openAllStockAlerts() {
        MainActor.assumeIsolated { openedAllStockAlerts += 1 }
    }
}
