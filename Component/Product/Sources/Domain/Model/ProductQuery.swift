public struct ProductQuery: Equatable, Sendable {
    public let filter: CatalogFilter
    public let page: Int
    public let pageSize: Int

    public init(filter: CatalogFilter, page: Int, pageSize: Int) {
        self.filter = filter
        self.page = page
        self.pageSize = pageSize
    }

    public static func all(page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(filter: .all, page: page, pageSize: pageSize)
    }

    public static func search(_ text: String, page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(filter: .search(text), page: page, pageSize: pageSize)
    }

    public static func category(_ category: ProductCategory, page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(filter: .category(category), page: page, pageSize: pageSize)
    }
}
