import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

@Suite("What a bag is worth")
struct BagTotalTests {
    @Test("One line is worth its line total")
    func single() {
        #expect(Bag(items: [item(1, at: 9.99)]).total == usd(9.99))
    }

    @Test("Several lines add up")
    func several() {
        #expect(Bag(items: [item(1, at: 9.99), item(2, at: 5.01)]).total == usd(15))
    }

    @Test("Quantities count")
    func quantities() {
        #expect(Bag(items: [item(1, quantity: 3, at: 10)]).total == usd(30))
    }

    @Test("Small amounts add exactly, with no drift")
    func noDrift() {
        let bag = Bag(items: [item(1, at: 0.10), item(2, at: 0.20)])

        #expect(bag.total == usd(0.30))
    }

    @Test("An empty bag is worth nothing at all rather than zero")
    func emptyIsNil() {
        #expect(Bag().total == nil)
    }

    @Test("How many things counts quantities, not lines")
    func itemCount() {
        #expect(Bag(items: [item(1, quantity: 2, at: 1), item(2, quantity: 3, at: 1)]).itemCount == 5)
    }
}
