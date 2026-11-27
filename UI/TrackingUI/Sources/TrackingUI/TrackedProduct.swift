import Money
import Product
import Tracking

/// How a product becomes something the shop can measure, said once for presentation and shared by
/// every screen that shows a product — a card, a page, a bag line, an order — where each would
/// otherwise keep its own copy and drift on which of a product's fields count.
public enum TrackedProduct {
    /// One of a product, at the price on its label — what a card or a page is showing.
    public static func item(_ product: Product) -> TrackedItem {
        item(product, price: product.price, quantity: 1)
    }

    /// A product at a price the shopper agreed to, and a quantity the event is about — a bag line
    /// keeps the price it was added at, an order the price that was paid.
    public static func item(_ product: Product, price: Money, quantity: Int) -> TrackedItem {
        .product(
            id: String(product.id.rawValue),
            name: product.title,
            category: product.category.rawValue,
            price: price,
            quantity: quantity
        )
    }
}
