import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Order

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
