// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of the catalogue. Those three hold for every protocol below, so they
// are cited once; each is named for what a shopper is trying to do, and its comment says only that.

/// A page of whatever slice of the shop the shopper is looking at.
public protocol BrowseCatalogUseCase: Sendable {
    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError>
}

/// The ways the shop divides up what it sells, for a shopper who would rather look than search.
public protocol BrowseCategoriesUseCase: Sendable {
    func callAsFunction() async -> Result<[ProductCategory], ProductError>
}

/// Filling in the things on a list the shopper already holds — a bag or a wishlist keeps ids alone.
public protocol LookUpProductsUseCase: Sendable {
    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError>
}

/// Everything the shop knows about one product a shopper has opened.
public protocol ViewProductUseCase: Sendable {
    func callAsFunction(id: ProductID) async -> Result<Product, ProductError>
}
