import Foundation
import Money
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: inside the `Bag` boundary, and holding
/// another aggregate by identity alone. What a product is called and looks like belongs to the
/// catalog; copying it here is how one model becomes five.
///
/// Evans — Value Objects; Side-Effect-Free Functions. Fowler, *PoEAA* (2002) — Money.
public struct BagItem: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let quantity: Int
    public let lastKnownPrice: Money
    public let dateAdded: Date

    public var id: ProductID { productId }

    public var lineTotal: Money { lastKnownPrice * quantity }

    public init(productId: ProductID, quantity: Int = 1, lastKnownPrice: Money, dateAdded: Date = Date()) {
        self.productId = productId
        self.quantity = quantity
        self.lastKnownPrice = lastKnownPrice
        self.dateAdded = dateAdded
    }

    public func withQuantity(_ quantity: Int) -> BagItem {
        BagItem(productId: productId, quantity: quantity, lastKnownPrice: lastKnownPrice, dateAdded: dateAdded)
    }

    public func withPrice(_ price: Money) -> BagItem {
        BagItem(productId: productId, quantity: quantity, lastKnownPrice: price, dateAdded: dateAdded)
    }
}
