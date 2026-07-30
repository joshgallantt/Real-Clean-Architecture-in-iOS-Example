import Foundation
import Money
import Product

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

    /// The catalog quotes bare numbers with no currency, so the one the shop sells in is
    /// supplied here. This is the only place that assumption lives: the day a second
    /// currency appears, it is a change to this line rather than a hunt through totals.
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

    /// The wire's two fields become the domain's one idea. `willRestock` says nothing while
    /// there is still stock, which is exactly why the domain does not carry it separately.
    private static func availability(stock: Int, willRestock: Bool) -> Availability {
        guard stock <= 0 else { return .inStock(remaining: stock) }
        return willRestock ? .outOfStock : .discontinued
    }
}

/// `discountPercentage` is on the wire and deliberately not carried inward. A bare
/// percentage cannot be acted on without knowing what it is a percentage *of* and whether
/// `price` is before or after it — and nothing in the app showed it. Reinstating it means
/// modelling what the shopper actually sees: a price alongside the list price it is down
/// from, which is two amounts, not one number.
struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]
    let total: Int
    let skip: Int
    let limit: Int
}
