import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Order

@Suite("Order")
struct OrderTotalTests {
    @Test("An order is worth the sum of its lines")
    func total() {
        #expect(order([line(1, at: 9.99), line(2, at: 5.01)]).total == usd(15))
    }

    @Test("Quantities are counted in the total")
    func totalWithQuantities() {
        #expect(order([line(1, quantity: 3, at: 10)]).total == usd(30))
    }

    @Test("Adding many small amounts does not drift")
    func totalDoesNotDrift() {
        #expect(order([line(1, at: 0.10), line(2, at: 0.20)]).total == usd(0.30))
        #expect(order((1...10).map { line($0, at: 0.01) }).total == usd(0.10))
    }

    @Test("An order with no lines is worth nothing at all, not zero")
    func emptyTotal() {
        #expect(order([]).total == nil)
    }

    @Test("How many things were bought counts the quantities")
    func itemCount() {
        #expect(order([line(1, quantity: 2, at: 1), line(2, quantity: 3, at: 1)]).itemCount == 5)
    }

    @Test("An empty order contains nothing")
    func emptyItemCount() {
        #expect(order([]).itemCount == 0)
    }

    @Test("An order keeps the moment it was placed")
    func placedAt() {
        let when = Date(timeIntervalSince1970: 1_000)

        #expect(order([line(1, at: 1)], at: when).placedAt == when)
    }

    @Test("An order keeps the payment it can be tied back to")
    func paymentReference() {
        #expect(order([line(1, at: 1)]).paymentReference == PaymentReference(rawValue: "ref"))
    }

    @Test("Every order gets its own id, even for the same things")
    func idsAreUnique() {
        #expect(order([line(1, at: 1)]).id != order([line(1, at: 1)]).id)
    }

    @Test("An id given is an id kept")
    func idIsKept() {
        let id = OrderID(rawValue: "abc")

        #expect(Order(id: id, lines: [line(1, at: 1)], paymentReference: PaymentReference(rawValue: "r")).id == id)
    }
}
