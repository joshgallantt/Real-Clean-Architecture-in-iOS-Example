import Foundation
import Money
import Order
import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import OrderUI

@MainActor
@Test("A placed order is confirmed with its reference, date and total")
func aPlacedOrderIsConfirmed() {
    assertSnapshot(
        of: OrderConfirmationView(order: OrderSummary(anOrder(quantity: 2)), done: {}),
        as: .image(layout: .device(config: .iPhone13))
    )
}

@MainActor
@Test("A single item is confirmed in the singular, not as one items")
func aSingleItemReadsAsSingular() {
    assertSnapshot(
        of: OrderConfirmationView(order: OrderSummary(anOrder(quantity: 1)), done: {}),
        as: .image(layout: .device(config: .iPhone13))
    )
}

/// The identifier and the date are both pinned. Left to their defaults they are
/// a fresh UUID and the moment the test ran, so the reference and the date
/// would be on the screen — and different — every time it recorded.
private func anOrder(quantity: Int) -> Order {
    Order(
        id: OrderID(rawValue: "8F2C1A44-0000-0000-0000-000000000000"),
        lines: [
            OrderLine(
                productId: ProductID(rawValue: 1),
                quantity: quantity,
                pricePaid: Money(amount: 24.99, currency: .usd)
            )
        ],
        placedAt: Date(timeIntervalSince1970: 1_700_000_000),
        paymentReference: PaymentReference(rawValue: "ref")
    )
}
