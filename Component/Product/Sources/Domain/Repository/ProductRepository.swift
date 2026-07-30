/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: declared by the
/// domain that needs it, implemented outward. The arrow points in, so the catalog's data layer
/// depends on this and never the reverse.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
public protocol ProductRepository: Sendable {
    func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError>
    func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError>
    func getProduct(id: ProductID) async -> Result<Product, ProductError>
    func getCategories() async -> Result<[ProductCategory], ProductError>
}
