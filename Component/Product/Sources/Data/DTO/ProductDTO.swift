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
            availability: Self.availability(stock: stock, willRestock: willRestock ?? true),
            brand: brand ?? "",
            thumbnail: thumbnail,
            images: images
        )
    }

    private static func availability(stock: Int, willRestock: Bool) -> Availability {
        guard stock <= 0 else { return .inStock(remaining: stock) }
        return willRestock ? .outOfStock : .discontinued
    }
}

struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]
    let total: Int
    let skip: Int
    let limit: Int
}
