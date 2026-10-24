import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the bag's invariants, one rule per test.
/// The acceptance suite says a shopper's bag was right when they came back; these say which rule
/// made it right — and name it when it is not.
@Suite("Bag invariants")
struct BagInvariantTests {
    @Test("A new bag is empty and worth nothing")
    func empty() {
        #expect(Bag().isEmpty)
        #expect(Bag().itemCount == 0)
        #expect(Bag().total == nil)
    }

    @Test("A line with none of it is not a line")
    func dropsZeroQuantity() {
        #expect(Bag(items: [item(1, quantity: 0, at: 5)]).isEmpty)
    }

    @Test("Nor is a line with less than none")
    func dropsNegativeQuantity() {
        #expect(Bag(items: [item(1, quantity: -2, at: 5)]).isEmpty)
    }

    @Test("One line per product — two of the same merge into one")
    func mergesDuplicates() {
        let bag = Bag(items: [item(1, quantity: 2, at: 5), item(1, quantity: 3, at: 5)])

        #expect(bag.items.count == 1)
        #expect(bag.quantity(of: pid(1)) == 5)
    }

    @Test("The newest thing chosen comes first")
    func newestFirst() {
        let bag = Bag(items: [
            item(1, at: 5, added: .distantPast),
            item(2, at: 5, added: .now)
        ])

        #expect(bag.items.map(\.productId) == [pid(2), pid(1)])
    }

    @Test("A bag holds what it holds")
    func holds() {
        let bag = Bag(items: [item(1, at: 5)])

        #expect(bag.holds(productId: pid(1)))
        #expect(bag.holds(productId: pid(2)) == false)
    }

    @Test("Asking how many of something it does not hold is none")
    func quantityOfNothing() {
        #expect(Bag().quantity(of: pid(1)) == 0)
    }
}
