import Foundation
import Money
import Product
import SnackbarUI
@testable import HomeUI

@MainActor
final class StubBrowseCatalog: BrowseCatalogUseCase, @unchecked Sendable {
    var resultsByCategory: [CategoryID: Result<[Product], ProductError>] = [:]
    var defaultResult: Result<[Product], ProductError> = .success([])
    private(set) var queries: [CatalogQuery] = []

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        guard case .category(let category) = query.filter else { return defaultResult }
        return resultsByCategory[category.id] ?? defaultResult
    }
}

@MainActor
final class StubBrowseCategories: BrowseCategoriesUseCase, @unchecked Sendable {
    var result: Result<[ProductCategory], ProductError> = .success([])
    private(set) var callCount = 0

    func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        callCount += 1
        return result
    }
}

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

@MainActor
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func products(
    _ ids: ClosedRange<Int>,
    category: String,
    availability: Availability = .inStock(remaining: 10)
) -> [Product] {
    ids.map { Product.fixture(id: $0, category: category, availability: availability) }
}

extension Product {
    static func fixture(
        id: Int,
        category: String = "beauty",
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: category),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}

/// Test-fixture categories only — production code never extends a domain type (see
/// `presentation-models-not-domain-extensions`), but a domain type inside a test fixture is fine.
extension ProductCategory {
    static let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
    static let fragrances = ProductCategory(id: CategoryID(rawValue: "fragrances"), name: "Fragrances")
    static let furniture = ProductCategory(id: CategoryID(rawValue: "furniture"), name: "Furniture")
}
