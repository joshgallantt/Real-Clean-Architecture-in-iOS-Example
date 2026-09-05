import Money
import Product
import Home
import ProductTestSupport
@testable import HomeUI

@MainActor
final class SpyHomeNavigation: HomeNavigation {
    private(set) var openedProducts: [ProductID] = []
    private(set) var openedCatalogs: [CatalogFilter] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product.id) }
    }

    nonisolated func openCatalog(filter: CatalogFilter) {
        MainActor.assumeIsolated { openedCatalogs.append(filter) }
    }
}
