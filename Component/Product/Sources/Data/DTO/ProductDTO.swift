import Foundation
import Money
import Product

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
public struct ProductDTO: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Decimal
    let rating: Double
    let stock: Int
    let willRestock: Bool?
    let brand: String?
    let thumbnail: String
    let images: [String]

    private static let currency = Currency.usd

    func toDomain() -> Product {
        Product(
            id: ProductID(rawValue: id),
            title: title,
            description: description,
            category: CategoryID(rawValue: category),
            price: Money(amount: price, currency: Self.currency),
            rating: rating,
            availability: stock > 0 ? .inStock(remaining: stock) : .outOfStock,
            brand: brand ?? "",
            thumbnail: thumbnail,
            images: images
        )
    }

    /// Whether this is a product the shop still sells at all. One that has run out and will not be
    /// restocked is gone for good, and gone for good is not something the domain is told — it is a
    /// product the data layer does not hand over, which is the same answer a 404 gives. Treating
    /// the two identically here is what lets everything above have one case to handle instead of
    /// two that mean the same thing.
    var isStillSold: Bool {
        stock > 0 || (willRestock ?? true)
    }
}

struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]
    let total: Int
    let skip: Int
    let limit: Int
}
