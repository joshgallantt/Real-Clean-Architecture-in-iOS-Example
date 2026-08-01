import Foundation
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
