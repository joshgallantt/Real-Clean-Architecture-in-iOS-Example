import Foundation
import Testing
import Bag

/// Coming back to a bag after the shop has moved on. This is the advisory half: correct
/// what can be corrected and record what changed, so the shopper is told rather than
/// left to notice. Nothing here is final — what they actually pay, and whether an
/// out-of-stock line can be fulfilled, is settled at checkout.
@Suite("Catching up with the shop")
struct BagReconciliationTests {

    private let bag = Bag(items: [
        BagItem(id: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
        BagItem(id: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: .now)
    ])

    @Test("A shop that says nothing has changed nothing")
    func nothingChanged() {
        let caughtUp = bag.reconciled(prices: [1: 9.99, 2: 49.99], inStock: [1: true, 2: true])

        #expect(caughtUp == bag)
        #expect(!caughtUp.hasPendingChanges)
    }

    @Test("A price that went up is applied, and recorded so the shopper can be told")
    func priceWentUp() {
        let caughtUp = bag.reconciled(prices: [1: 12.99])

        #expect(caughtUp.pendingChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(caughtUp.total.cents == 4999 + 2598)
    }

    @Test("A price that went down is applied too — the shopper should get the better one")
    func priceWentDown() {
        let caughtUp = bag.reconciled(prices: [1: 4.99])

        #expect(caughtUp.pendingChanges == [.priceWentDown(itemId: 1, from: 9.99, to: 4.99)])
        #expect(caughtUp.total.cents == 4999 + 998)
    }

    @Test("Something out of stock stays in the bag, and the shopper is told")
    func outOfStock() {
        let caughtUp = bag.reconciled(inStock: [1: false])

        // The shopper put it there. Whether to wait for it or give up on it is theirs
        // to decide, not the bag's.
        #expect(caughtUp.pendingChanges == [.outOfStock(itemId: 1)])
        #expect(caughtUp.items.map(\.id) == [2, 1])
        #expect(caughtUp.quantity(forItemId: 1) == 2)
    }

    @Test("A line the shop said nothing about is left exactly as it was")
    func silenceIsNotAnAnswer() {
        // A lookup that covered only part of the bag, or failed for one product, must
        // never read as "that product is gone".
        let caughtUp = bag.reconciled(prices: [2: 49.99], inStock: [2: true])

        #expect(caughtUp == bag)
    }

    @Test("Prices and stock arrive separately, and either alone is enough to act on")
    func factsAreIndependent() {
        let pricedOnly = bag.reconciled(prices: [1: 12.99])
        let stockOnly = bag.reconciled(inStock: [1: false])

        #expect(pricedOnly.pendingChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(stockOnly.pendingChanges == [.outOfStock(itemId: 1)])
        #expect(stockOnly.total.cents == bag.total.cents)
    }

    @Test("A line can be repriced and out of stock at once, and hears about both")
    func repricedAndOutOfStock() {
        let caughtUp = bag.reconciled(prices: [1: 12.99], inStock: [1: false])

        #expect(caughtUp.pendingChanges == [
            .priceWentUp(itemId: 1, from: 9.99, to: 12.99),
            .outOfStock(itemId: 1)
        ])
        #expect(caughtUp.total.cents == 4999 + 2598)
    }

    @Test("Catching up never takes anything out of the bag")
    func nothingIsEverRemoved() {
        let caughtUp = bag.reconciled(prices: [1: 4.99, 2: 59.99], inStock: [1: false, 2: false])

        #expect(caughtUp.items.map(\.id) == [2, 1])
        #expect(caughtUp.itemCount == 3)
    }

    @Test("A shopper away a long time hears about everything that moved, line by line")
    func manyChangesAtOnce() {
        let bag = Bag(items: [
            BagItem(id: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
            BagItem(id: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: Date(timeIntervalSince1970: 1)),
            BagItem(id: 3, quantity: 1, lastKnownPrice: 19.99, dateAdded: Date(timeIntervalSince1970: 2)),
            BagItem(id: 4, quantity: 1, lastKnownPrice: 5.99, dateAdded: .now)
        ])

        let caughtUp = bag.reconciled(
            prices: [1: 12.99, 2: 39.99, 3: 19.99],
            inStock: [1: true, 2: false, 3: true, 4: false]
        )

        // Reported newest line first, matching the order the shopper reads them in, and
        // both of item 2's problems are named rather than collapsed into one.
        #expect(caughtUp.pendingChanges == [
            .outOfStock(itemId: 4),
            .priceWentDown(itemId: 2, from: 49.99, to: 39.99),
            .outOfStock(itemId: 2),
            .priceWentUp(itemId: 1, from: 9.99, to: 12.99)
        ])
    }

    @Test("Reconciling an empty bag is a quiet no-op")
    func emptyBag() {
        let caughtUp = Bag().reconciled(inStock: [1: false])

        #expect(!caughtUp.hasPendingChanges)
        #expect(caughtUp.isEmpty)
    }
}

/// A shopper who never looks is owed the whole story, not the last instalment.
@Suite("Changes that pile up while nobody is looking")
struct PendingChangeTests {

    private let bag = Bag(items: [BagItem(id: 1, quantity: 1, lastKnownPrice: 10)])

    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() {
        let caughtUp = bag
            .reconciled(prices: [1: 12])
            .reconciled(prices: [1: 15])

        #expect(caughtUp.pendingChanges == [.priceWentUp(itemId: 1, from: 10, to: 15)])
        #expect(caughtUp.total.cents == 1500)
    }

    @Test("A price that moves up and back down again is no longer news")
    func moveAndMoveBack() {
        let caughtUp = bag
            .reconciled(prices: [1: 12])
            .reconciled(prices: [1: 10])

        #expect(!caughtUp.hasPendingChanges)
        #expect(caughtUp.total.cents == 1000)
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() {
        let caughtUp = bag
            .reconciled(prices: [1: 12])
            .reconciled(prices: [1: 8])

        #expect(caughtUp.pendingChanges == [.priceWentDown(itemId: 1, from: 10, to: 8)])
    }

    @Test("Stock that comes back retracts its own warning")
    func stockReturns() {
        let caughtUp = bag
            .reconciled(inStock: [1: false])
            .reconciled(inStock: [1: true])

        #expect(!caughtUp.hasPendingChanges)
    }

    @Test("Being told twice that something is out of stock is still one warning")
    func outOfStockIsNotRepeated() {
        let caughtUp = bag
            .reconciled(inStock: [1: false])
            .reconciled(inStock: [1: false])

        #expect(caughtUp.pendingChanges == [.outOfStock(itemId: 1)])
    }

    @Test("Saying it has been seen clears it, and the next move starts from there")
    func acknowledging() {
        let seen = bag.reconciled(prices: [1: 12]).acknowledging(itemId: 1)

        #expect(!seen.hasPendingChanges)
        #expect(seen.reconciled(prices: [1: 15]).pendingChanges
            == [.priceWentUp(itemId: 1, from: 12, to: 15)])
    }

    @Test("Saying one line has been seen leaves the others still waiting")
    func acknowledgingOneLine() {
        let caughtUp = Bag(items: [
            BagItem(id: 1, lastKnownPrice: 10, dateAdded: .distantPast),
            BagItem(id: 2, lastKnownPrice: 20, dateAdded: .now)
        ]).reconciled(inStock: [1: false, 2: false])

        #expect(caughtUp.acknowledging(itemId: 2).pendingChanges == [.outOfStock(itemId: 1)])
    }

    @Test("Taking something out takes its warning with it")
    func removingClearsItsChange() {
        let caughtUp = bag.reconciled(inStock: [1: false])

        #expect(!caughtUp.removing(itemId: 1).hasPendingChanges)
    }

    @Test("Choosing another one is seeing the price, so the warning has done its job")
    func addingAcknowledges() {
        let caughtUp = bag.reconciled(prices: [1: 12])

        #expect(!caughtUp.adding(BagItem(id: 1, lastKnownPrice: 12)).hasPendingChanges)
    }

    @Test("A warning about a line that is no longer in the bag is not a warning about anything")
    func changesCannotOutliveTheirLine() {
        let orphaned = Bag(items: [], pendingChanges: [.outOfStock(itemId: 1)])

        #expect(!orphaned.hasPendingChanges)
    }
}
