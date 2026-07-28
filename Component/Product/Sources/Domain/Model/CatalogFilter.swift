/// What subset of the catalog a request is asking for. Browsing everything is a
/// first-class intent, not the absence of a category — the Home tab is built on it,
/// and no category is involved anywhere in that flow.
public enum CatalogFilter: Equatable, Hashable, Sendable {
    case all
    case search(String)
    case category(ProductCategory)
}
