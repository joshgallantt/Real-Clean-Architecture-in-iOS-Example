import Foundation
import Money
import Product

extension Product {
    /// The union of the four variants that had grown separately: one exposed
    /// availability, one a price, one a category, one none of them. Which is
    /// the argument for a single fixture in the first place — each caller had
    /// widened its own copy for its own test and nobody else got the benefit.
    public static func fixture(
        id: Int,
        price: Decimal = 9.99,
        category: String = "beauty",
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: category),
            price: Money(amount: price, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
