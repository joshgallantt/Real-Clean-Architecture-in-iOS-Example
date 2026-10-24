import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

@Suite("BagItem")
struct BagItemTests {
    @Test("A line is worth its price times how many")
    func lineTotal() {
        #expect(item(1, quantity: 3, at: 4).lineTotal == usd(12))
    }

    @Test("One of something is worth its price")
    func lineTotalOfOne() {
        #expect(item(1, at: 4.25).lineTotal == usd(4.25))
    }

    @Test("A line is identified by its product")
    func identity() {
        #expect(item(6, at: 1).id == pid(6))
    }

    @Test("Changing how many keeps everything else")
    func withQuantity() {
        let changed = item(1, quantity: 1, at: 5, added: .distantPast).withQuantity(4)

        #expect(changed.quantity == 4)
        #expect(changed.lastKnownPrice == usd(5))
        #expect(changed.dateAdded == .distantPast)
    }

    @Test("Changing the price keeps everything else")
    func withPrice() {
        let changed = item(1, quantity: 2, at: 5, added: .distantPast).withPrice(usd(9))

        #expect(changed.lastKnownPrice == usd(9))
        #expect(changed.quantity == 2)
        #expect(changed.dateAdded == .distantPast)
    }
}
