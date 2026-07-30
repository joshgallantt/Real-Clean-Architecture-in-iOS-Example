/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: browsing everything is
/// an intent of its own, not the absence of a category.
public enum CatalogFilter: Equatable, Hashable, Sendable {
    case all
    case search(SearchTerm)
    case category(ProductCategory)
}
