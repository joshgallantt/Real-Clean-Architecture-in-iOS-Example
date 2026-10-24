import Networking
import Product

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol ProductClient: Sendable {
    func fetchProducts(query: CatalogQuery) async throws -> [ProductDTO]
    func fetchProduct(id: ProductID) async throws -> ProductDTO
    func fetchCategories() async throws -> [ProductCategoryDTO]
}
