import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: inside the `Order` boundary, holding
/// another aggregate by identity alone. What a product is called and looks like belongs to the
/// catalog, and both will have moved on — an order from last year must still read correctly when
/// the product has been renamed or withdrawn.
///
/// Evans, Ch. 5 — Value Objects. Fowler, *PoEAA* (2002), Ch. 18 — Money.
public struct OrderLine: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let quantity: Int

    /// What the shopper actually paid, frozen. `BagItem.lastKnownPrice` catches up when the shop
    /// changes its mind; this never does. A line that re-priced itself would make the order
    /// disagree with the money that moved.
    public let pricePaid: Money

    public var id: ProductID { productId }

    public var lineTotal: Money { pricePaid * quantity }

    public init(productId: ProductID, quantity: Int = 1, pricePaid: Money) {
        self.productId = productId
        self.quantity = quantity
        self.pricePaid = pricePaid
    }
}
