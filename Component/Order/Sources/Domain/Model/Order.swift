import Foundation
import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities: "An object defined primarily by its
/// identity is called an ENTITY." Two orders holding the same lines for the same money are still
/// two orders, which is why this has an id and `Bag` does not.
///
/// Evans, Ch. 6 — Aggregates: the root. Nothing here changes it — there is no `adding`, no
/// `removing`, no `changingQuantity`. A bag is a thing a shopper is still making up their mind
/// about; an order is a thing that happened. Placing it is the only write, and it happens once.
public struct Order: Equatable, Sendable, Identifiable {
    public let id: OrderID
    public let lines: [OrderLine]
    public let placedAt: Date

    /// What the payment was called by whoever took it. An order that cannot be tied back to a
    /// payment is a list, not a record.
    public let paymentReference: PaymentReference

    public init(
        id: OrderID = OrderID(),
        lines: [OrderLine],
        placedAt: Date = Date(),
        paymentReference: PaymentReference
    ) {
        self.id = id
        self.lines = lines
        self.placedAt = placedAt
        self.paymentReference = paymentReference
    }

    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: added from the lines, in whole minor units, so what
    /// is shown in a year's time is what was charged. Nothing at all when there are no lines —
    /// there is no currency in an empty order to name an amount in — though `PlaceOrderUseCase`
    /// will not make one.
    public var total: Money? {
        Money.total(of: lines.map(\.lineTotal))
    }

    public var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }
}

/// Fowler, *PoEAA* (2002), Ch. 12 — Identity Field. Evans, Ch. 5 — Entities: identity is the one
/// part of an order another context may hold, which is exactly why it is worth a type rather than
/// a `String` that could be a product id, a name or a payment reference.
public struct OrderID: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: UUID().uuidString)
    }
}
