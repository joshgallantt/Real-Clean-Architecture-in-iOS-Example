import Foundation

/// A line in the shopper's bag: which product, how many, and what it cost when the
/// shopper last saw it.
///
/// `lastKnownPrice` is not an agreement. A bag is a shopping list, not a contract — the
/// price is a quote the shopper was shown, kept so the bag can total itself with no
/// network, and refreshed whenever the catalog answers. What a shopper actually agrees
/// to pay is settled at checkout, against the shop's price, not this one.
///
/// `id` is a reference to another aggregate, which is the one part of it safe to hold.
/// Name and image are deliberately absent: they belong to the catalog, they mean the
/// same thing here as there, and copying them into every context that shows a product
/// is how one model becomes five.
public struct BagItem: Equatable, Sendable, Identifiable {
    public let id: Int
    public let quantity: Int
    public let lastKnownPrice: Double
    public let dateAdded: Date

    public init(id: Int, quantity: Int = 1, lastKnownPrice: Double, dateAdded: Date = Date()) {
        self.id = id
        self.quantity = quantity
        self.lastKnownPrice = lastKnownPrice
        self.dateAdded = dateAdded
    }

    public func withQuantity(_ quantity: Int) -> BagItem {
        BagItem(id: id, quantity: quantity, lastKnownPrice: lastKnownPrice, dateAdded: dateAdded)
    }

    public func withPrice(_ price: Double) -> BagItem {
        BagItem(id: id, quantity: quantity, lastKnownPrice: price, dateAdded: dateAdded)
    }
}
