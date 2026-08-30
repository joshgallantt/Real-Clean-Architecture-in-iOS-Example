import Foundation
import Money
import Product
import ProductTestSupport
@testable import Home

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
    static let furniture = ProductCategory(id: CategoryID(rawValue: "furniture"), name: "Furniture")
    static let kitchen = ProductCategory(id: CategoryID(rawValue: "kitchen"), name: "Kitchen")
    static let sports = ProductCategory(id: CategoryID(rawValue: "sports"), name: "Sports")
    static let toys = ProductCategory(id: CategoryID(rawValue: "toys"), name: "Toys")
    static let books = ProductCategory(id: CategoryID(rawValue: "books"), name: "Books")
}
