import Foundation
import Testing
import Money
import Order
@testable import OrderUI

@Suite("Order summary")
struct OrderSummaryTests {
    @Test("One item reads as singular")
    func oneItem() {
        let order = Order(
            lines: [OrderLine(productId: pid(1), quantity: 1, pricePaid: usd(9.99))],
            paymentReference: PaymentReference(rawValue: "ref")
        )

        #expect(OrderSummary(order).itemCount == "1 item")
    }

    @Test("More than one item is plural")
    func manyItems() {
        let order = Order(
            lines: [OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(9.99))],
            paymentReference: PaymentReference(rawValue: "ref")
        )

        #expect(OrderSummary(order).itemCount == "2 items")
    }

    @Test("The reference is the first 8 characters of the id, uppercased, behind a #")
    func reference() {
        let order = Order(
            id: OrderID(rawValue: "abc123def456"),
            lines: [OrderLine(productId: pid(1), pricePaid: usd(9.99))],
            paymentReference: PaymentReference(rawValue: "ref")
        )

        #expect(OrderSummary(order).reference == "#ABC123DE")
    }

    @Test("An order with no total renders as empty, not nil or a crash")
    func noTotal() {
        let order = Order(lines: [], paymentReference: PaymentReference(rawValue: "ref"))

        #expect(OrderSummary(order).total == "")
    }
}
