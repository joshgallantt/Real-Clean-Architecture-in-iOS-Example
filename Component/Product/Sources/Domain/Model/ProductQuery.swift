public struct ProductQuery: Equatable, Sendable {
    public let searchText: String?
    public let category: CategorySlug?
    public let page: Int
    public let pageSize: Int

    public init(searchText: String?, category: CategorySlug?, page: Int, pageSize: Int) {
        self.searchText = searchText
        self.category = category
        self.page = page
        self.pageSize = pageSize
    }

    public static func all(page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(searchText: nil, category: nil, page: page, pageSize: pageSize)
    }

    public static func search(_ text: String, page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(searchText: text, category: nil, page: page, pageSize: pageSize)
    }

    public static func category(_ slug: CategorySlug, page: Int, pageSize: Int) -> ProductQuery {
        ProductQuery(searchText: nil, category: slug, page: page, pageSize: pageSize)
    }
}
