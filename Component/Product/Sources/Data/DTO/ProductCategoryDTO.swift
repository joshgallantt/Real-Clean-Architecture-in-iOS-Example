import Product

public struct ProductCategoryDTO: Decodable {
    let slug: String
    let name: String

    func toDomain() -> ProductCategory {
        ProductCategory(id: CategoryID(rawValue: slug), name: name)
    }
}
