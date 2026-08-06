/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — a page of whatever slice of the shop the shopper is
/// looking at.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces. Fowler, *PoEAA*
/// (2002), Ch. 9 — Service Layer.
public protocol BrowseCatalogUseCase: Sendable {
    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — the ways the shop divides up what it sells, for a
/// shopper who would rather look than search.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol BrowseCategoriesUseCase: Sendable {
    func callAsFunction() async -> Result<[ProductCategory], ProductError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — filling in the things on a list the shopper already
/// holds — a bag or a wishlist keeps ids alone.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol LookUpProductsUseCase: Sendable {
    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — everything the shop knows about one product a shopper
/// has opened.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces. Fowler, *PoEAA*
/// (2002), Ch. 9 — Service Layer.
public protocol ViewProductUseCase: Sendable {
    func callAsFunction(id: ProductID) async -> Result<Product, ProductError>
}
