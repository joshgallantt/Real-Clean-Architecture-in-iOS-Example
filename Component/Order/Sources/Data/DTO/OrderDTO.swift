import Foundation
import Money
import Order
import Product

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: an order that cannot be
/// read back is dropped rather than throwing, so one unreadable entry does not cost a shopper the
/// rest of what they have bought.
struct OrderDTO: Codable, Sendable {
    let id: String
    let lines: [OrderLineDTO]
    let placedAt: Date
    let paymentReference: String

    init(from order: Order) {
        self.id = order.id.rawValue
        self.lines = order.lines.map(OrderLineDTO.init(from:))
        self.placedAt = order.placedAt
        self.paymentReference = order.paymentReference.rawValue
    }

    /// An order with no lines is not an order. It cannot be made through `PlaceOrderUseCase`, so
    /// one on disk is a corrupted entry rather than a state to render.
    func toDomain() -> Order? {
        guard !lines.isEmpty else { return nil }
        return Order(
            id: OrderID(rawValue: id),
            lines: lines.map { $0.toDomain() },
            placedAt: placedAt,
            paymentReference: PaymentReference(rawValue: paymentReference)
        )
    }
}

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
