import Foundation

/// A line in the shopper's bag: which product, how many, and what it cost when they last
/// saw it.
///
/// `lastKnownPrice` is not an agreement. A bag is a shopping list, not a contract — the
/// price is a quote the shopper was shown, kept so the bag can total itself with no
/// network, and refreshed whenever the catalog answers. What they actually agree to pay
/// is settled at checkout, against the shop's price, not this one.
///
/// `productId` is the only thing carried across from the catalog, because identity is the
/// one part of another aggregate it is safe to hold. What the product is called and what
/// it looks like belong to the catalog: they mean the same thing there, and copying them
/// into every context that shows a product is how one model becomes five.
public struct BagItem: Equatable, Sendable, Identifiable {
    public let productId: Int
    public let quantity: Int
    public let lastKnownPrice: Double
    public let dateAdded: Date

    /// A bag holds one line per product, so the product is what identifies the line.
    public var id: Int { productId }

    public init(productId: Int, quantity: Int = 1, lastKnownPrice: Double, dateAdded: Date = Date()) {
        self.productId = productId
        self.quantity = quantity
        self.lastKnownPrice = lastKnownPrice
        self.dateAdded = dateAdded
    }

    public func withQuantity(_ quantity: Int) -> BagItem {
        BagItem(productId: productId, quantity: quantity, lastKnownPrice: lastKnownPrice, dateAdded: dateAdded)
    }

    public func withPrice(_ price: Double) -> BagItem {
        BagItem(productId: productId, quantity: quantity, lastKnownPrice: price, dateAdded: dateAdded)
    }
}
