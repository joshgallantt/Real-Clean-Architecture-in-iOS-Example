import Foundation
import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: inside the `Bag` boundary, and holding
/// another aggregate by identity alone. What a product is called and looks like belongs to the
/// catalog; copying it here is how one model becomes five.
///
/// Evans, Ch. 5 — Value Objects; Ch. 10 — Side-Effect-Free Functions. Fowler, *PoEAA* (2002), Ch. 18 — Money.
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

    /// The line as the shop can supply it: at today's price, and no more of it than there is.
    func matching(_ product: Product) -> BagItem {
        withPrice(product.price).withQuantity(min(quantity, product.availability.remaining))
    }

    /// Two facts about a line the shop can still supply, told apart because they are two facts:
    /// what it costs now, if that is not what the line was kept at, and how many are left, if the
    /// line asks for more than that.
    ///
    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: exact amounts, so a price that did not move is no
    /// change at all. Float drift would manufacture one.
    func changes(nowThatTheShopSays product: Product) -> [BagChange] {
        var changes: [BagChange] = []

        if product.price > lastKnownPrice {
            changes.append(.priceWentUp(productId: productId, from: lastKnownPrice, to: product.price))
        } else if product.price < lastKnownPrice {
            changes.append(.priceWentDown(productId: productId, from: lastKnownPrice, to: product.price))
        }

        if quantity > product.availability.remaining {
            changes.append(.onlySomeLeft(productId: productId, available: product.availability.remaining))
        }

        return changes
    }
}
