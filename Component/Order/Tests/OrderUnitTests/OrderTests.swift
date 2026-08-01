import Foundation
import Testing
import Money
import Product
@testable import Order

private func pid(_ v: Int) -> ProductID { ProductID(rawValue: v) }
private func usd(_ a: Decimal) -> Money { Money(amount: a, currency: .usd) }
private func line(_ id: Int, quantity: Int = 1, at price: Decimal) -> OrderLine {
    OrderLine(productId: pid(id), quantity: quantity, pricePaid: usd(price))
}
private func order(_ lines: [OrderLine], at placed: Date = Date()) -> Order {
    Order(lines: lines, placedAt: placed, paymentReference: PaymentReference(rawValue: "ref"))
}

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: an order is a record of a transaction, so
/// most of its rules are about arithmetic that has to be exactly right. The acceptance suite says a
/// shopper bought something; these say what it was worth.
@Suite("OrderLine")
struct OrderLineTests {
    @Test("One of something costs what it costs")
    func single() {
        #expect(line(1, at: 9.99).lineTotal == usd(9.99))
    }

    @Test("Several of something multiply exactly, with no drift")
    func several() {
        #expect(line(1, quantity: 3, at: 0.10).lineTotal == usd(0.30))
    }

    @Test("A line of many is the price times the count")
    func many() {
        #expect(line(1, quantity: 7, at: 19.99).lineTotal == usd(139.93))
    }

    @Test("A line is identified by its product")
    func identity() {
        #expect(line(4, at: 1).id == pid(4))
    }

    @Test("The price paid is kept exactly as it was charged")
    func pricePaid() {
        #expect(line(1, at: 12.34).pricePaid == usd(12.34))
    }

    @Test("Two identical lines are equal")
    func equality() {
        #expect(line(1, quantity: 2, at: 5) == line(1, quantity: 2, at: 5))
        #expect(line(1, quantity: 2, at: 5) != line(1, quantity: 3, at: 5))
    }
}

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

@Suite("Orders")
struct OrdersTests {
    private func placed(_ id: String, at when: Date) -> Order {
        Order(
            id: OrderID(rawValue: id),
            lines: [line(1, at: 1)],
            placedAt: when,
            paymentReference: PaymentReference(rawValue: "r")
        )
    }

    @Test("A shopper who has bought nothing has nothing")
    func empty() {
        #expect(Orders().isEmpty)
        #expect(Orders().count == 0)
        #expect(Orders().mostRecent == nil)
    }

    @Test("An order placed is an order kept")
    func adding() {
        #expect(Orders().adding(placed("a", at: Date())).count == 1)
    }

    @Test("The newest order comes first")
    func newestFirst() {
        let orders = Orders()
            .adding(placed("old", at: .distantPast))
            .adding(placed("new", at: .now))

        #expect(orders.all.map(\.id.rawValue) == ["new", "old"])
    }

    @Test("The most recent is the newest of them")
    func mostRecent() {
        let orders = Orders()
            .adding(placed("old", at: .distantPast))
            .adding(placed("new", at: .now))

        #expect(orders.mostRecent?.id.rawValue == "new")
    }

    @Test("The same order twice is one order — a slow connection is not two purchases")
    func deduplicates() {
        let same = placed("a", at: Date())

        #expect(Orders().adding(same).adding(same).count == 1)
    }

    @Test("Building from duplicates keeps one of each")
    func initialiserDeduplicates() {
        let same = placed("a", at: Date())

        #expect(Orders([same, same]).count == 1)
    }

    @Test("Two different orders are both kept")
    func keepsDistinctOrders() {
        let orders = Orders()
            .adding(placed("a", at: .distantPast))
            .adding(placed("b", at: .now))

        #expect(orders.count == 2)
    }

    @Test("Adding never changes the list it was asked of")
    func sideEffectFree() {
        let before = Orders().adding(placed("a", at: Date()))
        _ = before.adding(placed("b", at: Date()))

        #expect(before.count == 1)
    }
}

@Suite("Order identifiers")
struct OrderIdentifierTests {
    @Test("A generated id is not empty")
    func generated() {
        #expect(OrderID().rawValue.isEmpty == false)
    }

    @Test("Two generated ids differ")
    func generatedAreUnique() {
        #expect(OrderID() != OrderID())
    }

    @Test("An id keeps what it was given")
    func rawValue() {
        #expect(OrderID(rawValue: "abc").rawValue == "abc")
    }

    @Test("Ids with the same value are the same id")
    func equality() {
        #expect(OrderID(rawValue: "a") == OrderID(rawValue: "a"))
        #expect(OrderID(rawValue: "a") != OrderID(rawValue: "b"))
    }

    @Test("A payment reference keeps what the processor called it")
    func paymentReference() {
        #expect(PaymentReference(rawValue: "txn_1").rawValue == "txn_1")
        #expect(PaymentReference(rawValue: "txn_1") == PaymentReference(rawValue: "txn_1"))
    }
}

@Suite("Failing to order")
struct OrderErrorTests {
    @Test("A decline is not the same failure as being unable to reach anybody")
    func declineIsDistinct() {
        #expect(OrderError.paymentDeclined != OrderError.unavailable)
    }

    @Test("Being signed out is its own failure")
    func unauthenticatedIsDistinct() {
        #expect(OrderError.unauthenticated != OrderError.paymentDeclined)
    }

    @Test("Having nothing to buy is its own failure, not a silent success")
    func nothingToOrderIsDistinct() {
        #expect(OrderError.nothingToOrder != OrderError.unavailable)
    }

    @Test("A payment failure is told apart the same way")
    func paymentFailures() {
        #expect(PaymentFailure.declined != PaymentFailure.unavailable)
    }
}
