/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: named for the catalog it asks about,
/// because a shopper's own words are a `SearchTerm` and calling both a query leaves neither name
/// meaning anything.
///
/// Evans — Value Objects.
public struct CatalogQuery: Equatable, Sendable {
    public let filter: CatalogFilter
    public let page: Int
    public let pageSize: Int

    public init(filter: CatalogFilter, page: Int, pageSize: Int) {
        self.filter = filter
        self.page = page
        self.pageSize = pageSize
    }

    public static func all(page: Int, pageSize: Int) -> CatalogQuery {
        CatalogQuery(filter: .all, page: page, pageSize: pageSize)
    }

    public static func search(_ term: SearchTerm, page: Int, pageSize: Int) -> CatalogQuery {
        CatalogQuery(filter: .search(term), page: page, pageSize: pageSize)
    }

    public static func category(_ category: ProductCategory, page: Int, pageSize: Int) -> CatalogQuery {
        CatalogQuery(filter: .category(category), page: page, pageSize: pageSize)
    }
}
