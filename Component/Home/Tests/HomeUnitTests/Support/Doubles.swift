import Foundation
import Money
import Product
@testable import Home

final class StubBrowseCatalog: BrowseCatalogUseCase, @unchecked Sendable {
    var resultsByCategory: [CategoryID: Result<[Product], ProductError>] = [:]
    private(set) var queries: [CatalogQuery] = []

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        guard case .category(let category) = query.filter else { return .success([]) }
        return resultsByCategory[category.id] ?? .success([])
    }
}

final class StubBrowseCategories: BrowseCategoriesUseCase, @unchecked Sendable {
    var result: Result<[ProductCategory], ProductError> = .success([])

    func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        result
    }
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
    static let kitchen = ProductCategory(id: CategoryID(rawValue: "kitchen"), name: "Kitchen")
    static let sports = ProductCategory(id: CategoryID(rawValue: "sports"), name: "Sports")
    static let toys = ProductCategory(id: CategoryID(rawValue: "toys"), name: "Toys")
    static let books = ProductCategory(id: CategoryID(rawValue: "books"), name: "Books")
}
