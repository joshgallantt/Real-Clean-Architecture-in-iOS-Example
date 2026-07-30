import Product

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
public struct ProductCategoryDTO: Decodable {
    let slug: String
    let name: String

    func toDomain() -> ProductCategory {
        ProductCategory(id: CategoryID(rawValue: slug), name: name)
    }
}
