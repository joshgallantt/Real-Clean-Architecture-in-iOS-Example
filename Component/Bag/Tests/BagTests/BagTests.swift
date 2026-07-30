import Foundation
import Testing
import Bag
import Money

@Suite("What a bag costs")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the domain is tested with no
/// repository, no store and no simulator in the room. Anything here that needed one would not be a
/// domain rule.
struct BagCostTests {
    @Test("An empty bag holds nothing, and is not worth zero of anything in particular")
    func emptyBag() {
        let bag = Bag()

        #expect(bag.isEmpty)
        #expect(bag.itemCount == 0)
        #expect(bag.total == nil)
    }

    @Test("The total is each line's last known price times how many the shopper took")
    func total() {
        let bag = Bag(items: [
            item(1, quantity: 2, price: 9.99),
            item(2, quantity: 1, price: 2499.99)
        ])

        #expect(bag.total == usd(2519.97))
    }

    @Test("Adding prices up is exact, so a total is never a hair off what the lines say")
    func totalIsExact() {
        let bag = Bag(items: [
            item(1, price: 9.99),
            item(2, price: 49.99)
        ])

        #expect(bag.total == usd(59.98))
    }

    @Test("A bag totals correctly with nothing loaded, because nothing needs loading")
    func totalNeedsNothingFetched() {
        let bag = Bag(items: [item(1, quantity: 3, price: 4.99)])

        #expect(bag.total == usd(14.97))
    }

    @Test("Taking three of one thing counts as three items, not one")
    func itemCount() {
        let bag = Bag(items: [
            item(1, quantity: 3, price: 9.99),
            item(2, quantity: 2, price: 12.99)
        ])

        #expect(bag.itemCount == 5)
    }

    @Test("A bag can say how many of something it holds, including none")
    func quantityForItem() {
        let bag = Bag(items: [item(1, quantity: 3, price: 9.99)])

        #expect(bag.quantity(of: pid(1)) == 3)
        #expect(bag.quantity(of: pid(99)) == 0)
    }
}

@Suite("States a bag cannot be in")
/// Evans, *Domain-Driven Design* (2003) — Aggregates: the states the root says it will not be in,
/// asserted at the only door into one. A documented invariant the initialiser does not impose is
/// held only by the good manners of every caller.
struct BagInvariantTests {
    @Test("Two lines for one product become one line with both counts")
    func duplicateLinesAreMerged() {
        let bag = Bag(items: [
            item(1, quantity: 2, price: 9.99, addedAt: .distantPast),
            item(1, quantity: 3, price: 19.99, addedAt: .now)
        ])

        #expect(bag.items.count == 1)
        #expect(bag.quantity(of: pid(1)) == 5)
        #expect(bag.items.first?.lastKnownPrice == usd(9.99))
    }

    @Test("A line with none of something is not a line")
    func zeroQuantityLinesAreDropped() {
        let bag = Bag(items: [
            item(1, quantity: 0, price: 9.99),
            item(2, quantity: 1, price: 9.99)
        ])

        #expect(bag.items.map(\.id) == [pid(2)])
    }

    @Test("A line with less than none of something is not a line either")
    func negativeQuantityLinesAreDropped() {
        let bag = Bag(items: [item(1, quantity: -3, price: 9.99)])

        #expect(bag.isEmpty)
        #expect(bag.total == nil)
    }

    @Test("A bag rebuilt from a file written by an older build is put right, not trusted")
    func repairsWhateverItIsHanded() {
        let bag = Bag(items: [
            item(1, quantity: 1, price: 5, addedAt: Date(timeIntervalSince1970: 100)),
            item(2, quantity: 0, price: 5, addedAt: Date(timeIntervalSince1970: 200)),
            item(1, quantity: 1, price: 5, addedAt: Date(timeIntervalSince1970: 300)),
            item(3, quantity: 2, price: 5, addedAt: Date(timeIntervalSince1970: 400))
        ])

        #expect(bag.items.map(\.id) == [pid(3), pid(1)])
        #expect(bag.quantity(of: pid(1)) == 2)
        #expect(bag.total == usd(20))
    }
}

@Suite("How a bag changes")
struct BagChangeTests {
    @Test("Choosing something new puts it in the bag")
    func addingSomethingNew() {
        let bag = Bag().adding(item(1, price: 9.99))

        #expect(bag.items.map(\.id) == [pid(1)])
        #expect(bag.total == usd(9.99))
    }

    @Test("Choosing something already in the bag takes another of it, rather than listing it twice")
    func addingSomethingAlreadyThere() {
        let bag = Bag()
            .adding(item(1, price: 9.99))
            .adding(item(1, price: 9.99))

        #expect(bag.items.count == 1)
        #expect(bag.quantity(of: pid(1)) == 2)
    }

    @Test("Taking another at today's price moves the whole line to today's price")
    func addingAgainReprices() {
        let bag = Bag()
            .adding(item(1, price: 4.99))
            .adding(item(1, price: 9.99))

        #expect(bag.items.first?.lastKnownPrice == usd(9.99))
        #expect(bag.total == usd(19.98))
    }

    @Test("The newest thing chosen sits at the top of the bag")
    func newestFirst() {
        let bag = Bag()
            .adding(item(1, price: 1, addedAt: .distantPast))
            .adding(item(2, price: 2, addedAt: .now))

        #expect(bag.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("A bag handed its lines in any order still holds them newest first")
    func ordersWhateverItIsGiven() {
        let older = item(1, price: 1, addedAt: .distantPast)
        let newer = item(2, price: 2, addedAt: .now)

        #expect(Bag(items: [older, newer]).items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Asking for none of something is how a shopper puts it back")
    func zeroQuantityRemoves() {
        let bag = Bag()
            .adding(item(1, price: 9.99))
            .changingQuantity(of: pid(1), to: 0)

        #expect(bag.isEmpty)
    }

    @Test("Changing a quantity leaves the price alone")
    func quantityChangeKeepsPrice() {
        let bag = Bag()
            .adding(item(1, price: 4.99))
            .changingQuantity(of: pid(1), to: 3)

        #expect(bag.total == usd(14.97))
    }

    @Test("Changing the quantity of something not in the bag changes nothing")
    func quantityChangeForAbsentItem() {
        let bag = Bag().adding(item(1, price: 9.99))

        #expect(bag.changingQuantity(of: pid(99), to: 5) == bag)
    }

    @Test("Putting something back leaves the rest of the bag alone")
    func removingLeavesTheRest() {
        let bag = Bag()
            .adding(item(1, price: 1))
            .adding(item(2, price: 2))

        #expect(bag.removing(productId: pid(1)).items.map(\.id) == [pid(2)])
    }

    @Test("Putting back something that was never in the bag changes nothing")
    func removingSomethingAbsent() {
        let bag = Bag().adding(item(1, price: 1))

        #expect(bag.removing(productId: pid(99)) == bag)
    }
}
