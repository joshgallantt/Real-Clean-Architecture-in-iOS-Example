import Product

public struct ProductCategoryDTO: Decodable {
    let slug: String
    let name: String

    func toDomain() -> ProductCategory {
        ProductCategory(slug: CategorySlug(value: slug), name: name)
    }
}
