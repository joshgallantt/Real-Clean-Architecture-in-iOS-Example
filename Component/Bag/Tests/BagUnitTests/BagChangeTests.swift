import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

@Suite("Changing a bag")
struct BagChangeTests {
    @Test("Adding something new puts it in")
    func addingNew() {
        #expect(Bag().adding(item(1, at: 5)).quantity(of: pid(1)) == 1)
    }

    @Test("Adding something already there adds to it")
    func addingMore() {
        let bag = Bag(items: [item(1, quantity: 2, at: 5)]).adding(item(1, quantity: 3, at: 5))

        #expect(bag.quantity(of: pid(1)) == 5)
        #expect(bag.items.count == 1)
    }

    @Test("Adding again takes the newer price")
    func addingTakesNewPrice() {
        let bag = Bag(items: [item(1, at: 5)]).adding(item(1, at: 7))

        #expect(bag.total == usd(14))
    }

    @Test("Removing takes the line out")
    func removing() {
        #expect(Bag(items: [item(1, at: 5)]).removing(productId: pid(1)).isEmpty)
    }

    @Test("Removing leaves the other lines alone")
    func removingOne() {
        let bag = Bag(items: [item(1, at: 5), item(2, at: 5)]).removing(productId: pid(1))

        #expect(bag.items.map(\.productId) == [pid(2)])
    }

    @Test("Removing what is not there changes nothing")
    func removingNothing() {
        let bag = Bag(items: [item(1, at: 5)])

        #expect(bag.removing(productId: pid(9)) == bag)
    }

    @Test("Changing how many changes how many")
    func changingQuantity() {
        #expect(Bag(items: [item(1, at: 5)]).changingQuantity(of: pid(1), to: 4).quantity(of: pid(1)) == 4)
    }

    @Test("Changing to none takes the line out")
    func changingToZero() {
        #expect(Bag(items: [item(1, at: 5)]).changingQuantity(of: pid(1), to: 0).isEmpty)
    }

    @Test("Changing to less than none takes it out too")
    func changingToNegative() {
        #expect(Bag(items: [item(1, at: 5)]).changingQuantity(of: pid(1), to: -1).isEmpty)
    }

    @Test("Changing how many of something never chosen changes nothing")
    func changingWhatIsNotThere() {
        let bag = Bag(items: [item(1, at: 5)])

        #expect(bag.changingQuantity(of: pid(9), to: 3) == bag)
    }

    @Test("Changing how many keeps the price the shopper was quoted")
    func changingKeepsPrice() {
        let bag = Bag(items: [item(1, at: 5)]).changingQuantity(of: pid(1), to: 2)

        #expect(bag.total == usd(10))
    }

    @Test("Changing never alters the bag it was asked of")
    func sideEffectFree() {
        let before = Bag(items: [item(1, at: 5)])
        _ = before.changingQuantity(of: pid(1), to: 9)

        #expect(before.quantity(of: pid(1)) == 1)
    }
}
