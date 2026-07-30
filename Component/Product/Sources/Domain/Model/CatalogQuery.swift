/// One request for a page of the catalog: which subset, and how far in.
///
/// Named for the catalog rather than the product, because it asks about a slice of the shop
/// and answers with many products. "Query" on its own is taken — a shopper's own words are
/// a `SearchTerm`, and calling both a query means neither name says which is meant.
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
