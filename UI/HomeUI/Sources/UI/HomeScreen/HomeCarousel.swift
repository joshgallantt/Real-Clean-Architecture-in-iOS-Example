import Product

/// Evans, *Domain-Driven Design* (2003) — Value Objects: a category paired with the products drawn
/// for it, held together because they were drawn together — never recomputed from `products` alone,
/// since an empty carousel and one that never earned a place on Home are the same shape otherwise.
struct HomeCarousel: Equatable, Identifiable {
    let category: ProductCategory
    let products: [Product]

    var id: CategoryID { category.id }
}
