public struct ProductCategory: Equatable, Hashable, Sendable, Identifiable {
    public let slug: CategorySlug
    public let name: String

    public var id: CategorySlug { slug }

    public init(slug: CategorySlug, name: String) {
        self.slug = slug
        self.name = name
    }
}
