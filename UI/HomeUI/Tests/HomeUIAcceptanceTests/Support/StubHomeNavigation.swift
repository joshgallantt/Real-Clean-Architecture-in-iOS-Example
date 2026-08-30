import Product
@testable import HomeUI

@MainActor
/// The app layer conforms `Navigator` to this. Home only ever opens a product or a category's
/// results, so that is all the test needs to know about.
final class StubHomeNavigation: HomeNavigation {
    private(set) var openedProducts: [ProductID] = []
    private(set) var openedCatalogs: [CatalogFilter] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product.id) }
    }

    nonisolated func openCatalog(filter: CatalogFilter) {
        MainActor.assumeIsolated { openedCatalogs.append(filter) }
    }
}
