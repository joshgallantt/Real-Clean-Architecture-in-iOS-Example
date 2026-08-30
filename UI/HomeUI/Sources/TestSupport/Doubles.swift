// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import Foundation
import Money
import Product
import Home
import ProductTestSupport
@testable import HomeUI

@MainActor
final class StubNavigation: HomeNavigation {
    private(set) var openedProducts: [ProductID] = []
    private(set) var openedCatalogs: [CatalogFilter] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product.id) }
    }

    nonisolated func openCatalog(filter: CatalogFilter) {
        MainActor.assumeIsolated { openedCatalogs.append(filter) }
    }
}

/// The carousels a loaded Home drew, or none at all. A unit test may name the state it expects
/// directly; this is only so the ones about *what was drawn* do not have to unwrap it each time.
extension HomeScreenState {
    var carousels: [HomeCarousel] {
        guard case .loaded(let feed) = self else { return [] }
        return feed.carousels
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func products(
    _ ids: ClosedRange<Int>,
    category: String,
    availability: Availability = .inStock(remaining: 10)
) -> [Product] {
    ids.map { Product.fixture(id: $0, category: category, availability: availability) }
}

/// Test-fixture categories only — production code never extends a domain type (see
/// `presentation-models-not-domain-extensions`), but a domain type inside a test fixture is fine.
extension ProductCategory {
    static let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
    static let fragrances = ProductCategory(id: CategoryID(rawValue: "fragrances"), name: "Fragrances")
}
