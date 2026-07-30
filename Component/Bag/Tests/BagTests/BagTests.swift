import Foundation
import Testing
import Bag

/// Everything the bag decides, decided without a repository, a store or a catalog in
/// the room. If any of this needed one, it would not be the bag's rule.
@Suite("What a bag costs")
struct BagCostTests {

    @Test("An empty bag costs nothing and holds nothing")
    func emptyBag() {
        let bag = Bag()

        #expect(bag.isEmpty)
        #expect(bag.total.cents == 0)
        #expect(bag.itemCount == 0)
    }

    @Test("The total is each line's last known price times how many the shopper took")
    func total() {
        let bag = Bag(items: [
            BagItem(productId: 1, quantity: 2, lastKnownPrice: 9.99),
            BagItem(productId: 2, quantity: 1, lastKnownPrice: 2499.99)
        ])

        #expect(bag.total.cents == 251997)
    }

    @Test("A bag totals correctly with nothing loaded, because nothing needs loading")
    func totalNeedsNothingFetched() {
        // No names, no pictures, no catalog: the bag keeps the last prices it was
        // shown, so it can still say what it is worth.
        let bag = Bag(items: [BagItem(productId: 1, quantity: 3, lastKnownPrice: 4.99)])

        #expect(bag.total.cents == 1497)
    }

    @Test("Taking three of one thing counts as three items, not one")
    func itemCount() {
        let bag = Bag(items: [
            BagItem(productId: 1, quantity: 3, lastKnownPrice: 9.99),
            BagItem(productId: 2, quantity: 2, lastKnownPrice: 12.99)
        ])

        #expect(bag.itemCount == 5)
    }

    @Test("A bag can say how many of something it holds, including none")
    func quantityForItem() {
        let bag = Bag(items: [BagItem(productId: 1, quantity: 3, lastKnownPrice: 9.99)])

        #expect(bag.quantity(of: 1) == 3)
        #expect(bag.quantity(of: 99) == 0)
    }
}

@Suite("How a bag changes")
struct BagChangeTests {

    @Test("Choosing something new puts it in the bag")
    func addingSomethingNew() {
        let bag = Bag().adding(BagItem(productId: 1, lastKnownPrice: 9.99))

        #expect(bag.items.map(\.id) == [1])
        #expect(bag.total.cents == 999)
    }

    @Test("Choosing something already in the bag takes another of it, rather than listing it twice")
    func addingSomethingAlreadyThere() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 9.99))
            .adding(BagItem(productId: 1, lastKnownPrice: 9.99))

        #expect(bag.items.count == 1)
        #expect(bag.quantity(of: 1) == 2)
    }

    @Test("Taking another at today's price moves the whole line to today's price")
    func addingAgainReprices() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 4.99))
            .adding(BagItem(productId: 1, lastKnownPrice: 9.99))

        // The alternative leaves the shopper paying last week's price for both, which
        // is wrong in whichever direction the price moved.
        #expect(bag.items.first?.lastKnownPrice == 9.99)
        #expect(bag.total.cents == 1998)
    }

    @Test("The newest thing chosen sits at the top of the bag")
    func newestFirst() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 1, dateAdded: .distantPast))
            .adding(BagItem(productId: 2, lastKnownPrice: 2, dateAdded: .now))

        #expect(bag.items.map(\.id) == [2, 1])
    }

    @Test("A bag handed its lines in any order still holds them newest first")
    func ordersWhateverItIsGiven() {
        let older = BagItem(productId: 1, lastKnownPrice: 1, dateAdded: .distantPast)
        let newer = BagItem(productId: 2, lastKnownPrice: 2, dateAdded: .now)

        #expect(Bag(items: [older, newer]).items.map(\.id) == [2, 1])
    }

    @Test("Asking for none of something is how a shopper puts it back")
    func zeroQuantityRemoves() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 9.99))
            .changingQuantity(of: 1, to: 0)

        #expect(bag.isEmpty)
    }

    @Test("Changing a quantity leaves the price alone")
    func quantityChangeKeepsPrice() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 4.99))
            .changingQuantity(of: 1, to: 3)

        #expect(bag.total.cents == 1497)
    }

    @Test("Changing the quantity of something not in the bag changes nothing")
    func quantityChangeForAbsentItem() {
        let bag = Bag().adding(BagItem(productId: 1, lastKnownPrice: 9.99))

        #expect(bag.changingQuantity(of: 99, to: 5) == bag)
    }

    @Test("Putting something back leaves the rest of the bag alone")
    func removingLeavesTheRest() {
        let bag = Bag()
            .adding(BagItem(productId: 1, lastKnownPrice: 1))
            .adding(BagItem(productId: 2, lastKnownPrice: 2))

        #expect(bag.removing(productId: 1).items.map(\.id) == [2])
    }

    @Test("Putting back something that was never in the bag changes nothing")
    func removingSomethingAbsent() {
        let bag = Bag().adding(BagItem(productId: 1, lastKnownPrice: 1))

        #expect(bag.removing(productId: 99) == bag)
    }
}
