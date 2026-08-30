import Money
import Product
import Home
import ProductTestSupport
@testable import HomeUI

/// Test-fixture categories only — production code never extends a domain type (see
/// `presentation-models-not-domain-extensions`), but a domain type inside a test fixture is fine.
extension ProductCategory {
    static let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
    static let fragrances = ProductCategory(id: CategoryID(rawValue: "fragrances"), name: "Fragrances")
}
