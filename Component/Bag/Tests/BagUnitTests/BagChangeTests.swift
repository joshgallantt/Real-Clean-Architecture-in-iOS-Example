import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

@Suite("Changing a bag")
struct BagChangeTests {
    @Test("Setting something new puts it in")
    func settingNew() {
        #expect(Bag().setting(item(1, at: 5)).quantity(of: pid(1)) == 1)
    }

    @Test("Setting something already there makes it that many, not that many more")
    func settingReplaces() {
        let bag = Bag(items: [item(1, quantity: 2, at: 5)]).setting(item(1, quantity: 3, at: 5))

        #expect(bag.quantity(of: pid(1)) == 3)
        #expect(bag.items.count == 1)
    }

    @Test("Setting takes the price it was given")
    func settingTakesPrice() {
        let bag = Bag(items: [item(1, at: 5)]).setting(item(1, quantity: 2, at: 7))

        #expect(bag.total == usd(14))
    }

    @Test("A line keeps its place when how many changes")
    func settingKeepsPlace() {
        let old = BagItem(productId: pid(1), quantity: 1, lastKnownPrice: usd(5), dateAdded: .distantPast)
        let new = BagItem(productId: pid(2), quantity: 1, lastKnownPrice: usd(5), dateAdded: .now)

        let bag = Bag(items: [old, new]).setting(item(1, quantity: 4, at: 5))

        #expect(bag.items.map(\.productId) == [pid(2), pid(1)])
    }

    @Test("Setting to none takes the line out")
    func settingToZero() {
        #expect(Bag(items: [item(1, at: 5)]).setting(item(1, quantity: 0, at: 5)).isEmpty)
    }

    @Test("Setting to less than none takes it out too")
    func settingToNegative() {
        #expect(Bag(items: [item(1, at: 5)]).setting(item(1, quantity: -1, at: 5)).isEmpty)
    }

    @Test("Setting none of something never chosen changes nothing")
    func settingNoneOfNothing() {
        let bag = Bag(items: [item(1, at: 5)])

        #expect(bag.setting(item(9, quantity: 0, at: 5)) == bag)
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

    @Test("Setting never alters the bag it was asked of")
    func sideEffectFree() {
        let before = Bag(items: [item(1, at: 5)])
        _ = before.setting(item(1, quantity: 9, at: 5))

        #expect(before.quantity(of: pid(1)) == 1)
    }
}
