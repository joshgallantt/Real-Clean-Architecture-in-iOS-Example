import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Order

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
