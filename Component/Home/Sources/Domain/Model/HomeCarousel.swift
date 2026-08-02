import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Value Objects: a category paired with the products
/// drawn for it, held together because they were drawn together — never recomputed from `products`
/// alone, since an empty carousel and one that never earned a place on Home are the same shape
/// otherwise.
public struct HomeCarousel: Equatable, Identifiable, Sendable {
    public let category: ProductCategory
    public let products: [Product]

    public var id: CategoryID { category.id }

    public init(category: ProductCategory, products: [Product]) {
        self.category = category
        self.products = products
    }
}
