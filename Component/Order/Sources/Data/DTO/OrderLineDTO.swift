import Money
import Order
import Product

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object.
struct OrderLineDTO: Codable, Sendable {
    let productId: Int
    let quantity: Int
    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: stored as whole minor units, so an order read back
    /// off disk totals to exactly what was charged.
    let pricePaidMinorUnits: Int
    let currencyCode: String

    init(from line: OrderLine) {
        self.productId = line.productId.rawValue
        self.quantity = line.quantity
        self.pricePaidMinorUnits = line.pricePaid.minorUnits
        self.currencyCode = line.pricePaid.currency.code
    }

    func toDomain() -> OrderLine {
        OrderLine(
            productId: ProductID(rawValue: productId),
            quantity: quantity,
            pricePaid: Money(
                minorUnits: pricePaidMinorUnits,
                currency: Currency(code: currencyCode, minorUnitsPerMajor: 100)
            )
        )
    }
}
