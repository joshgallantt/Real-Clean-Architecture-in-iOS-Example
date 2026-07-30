import Foundation
import Testing
import Bag

/// Coming back to a bag after the shop has moved on. This is the advisory half: correct
/// what can be corrected, take out what cannot be supplied, and record why — so the
/// shopper is told rather than left to notice a shorter list.
@Suite("Catching up with the shop")
struct BagReconciliationTests {

    private let bag = Bag(items: [
        BagItem(id: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
        BagItem(id: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: .now)
    ])

    @Test("A shop that says nothing has changed nothing")
    func nothingChanged() {
        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            prices: [1: 9.99, 2: 49.99], inStock: [1: true, 2: true]
        )

        #expect(caughtUp.bag == bag)
        #expect(caughtUp.changes.isEmpty)
    }

    @Test("A price that went up is applied, and recorded so the shopper can be told")
    func priceWentUp() {
        let caughtUp = BagReconciliation.reconcile(bag: bag, changes: BagChanges(), prices: [1: 12.99])

        #expect(caughtUp.changes.priceChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(caughtUp.bag.total.cents == 4999 + 2598)
    }

    @Test("A price that went down is applied too — the shopper should get the better one")
    func priceWentDown() {
        let caughtUp = BagReconciliation.reconcile(bag: bag, changes: BagChanges(), prices: [1: 4.99])

        #expect(caughtUp.changes.priceChanges == [.priceWentDown(itemId: 1, from: 9.99, to: 4.99)])
        #expect(caughtUp.bag.total.cents == 4999 + 998)
    }

    @Test("Something out of stock leaves the bag, and the shopper is told it went")
    func outOfStock() {
        let caughtUp = BagReconciliation.reconcile(bag: bag, changes: BagChanges(), inStock: [1: false])

        // A bag is what the shopper is going to buy, and a line that cannot be bought
        // does not belong in it.
        #expect(caughtUp.bag.items.map(\.id) == [2])
        #expect(caughtUp.changes.removals == [.outOfStock(itemId: 1)])
        #expect(caughtUp.bag.total.cents == 4999)
    }

    @Test("A line the shop said nothing about is left exactly as it was")
    func silenceIsNotAnAnswer() {
        // A lookup that covered only part of the bag, or failed for one product, must
        // never read as "that product is gone".
        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            prices: [2: 49.99], inStock: [2: true]
        )

        #expect(caughtUp.bag == bag)
        #expect(caughtUp.changes.isEmpty)
    }

    @Test("Prices and stock arrive separately, and either alone is enough to act on")
    func factsAreIndependent() {
        let pricedOnly = BagReconciliation.reconcile(bag: bag, changes: BagChanges(), prices: [1: 12.99])
        let stockOnly = BagReconciliation.reconcile(bag: bag, changes: BagChanges(), inStock: [1: false])

        #expect(pricedOnly.changes.priceChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(pricedOnly.bag.items.map(\.id) == bag.items.map(\.id))
        #expect(stockOnly.changes.removals == [.outOfStock(itemId: 1)])
        #expect(stockOnly.bag.items.map(\.id) == [2])
    }

    @Test("What a line's price did on the way out is not news")
    func repricedAndOutOfStock() {
        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            prices: [1: 12.99], inStock: [1: false]
        )

        // Telling a shopper what something costs and that they cannot have it is two
        // messages where one will do.
        #expect(caughtUp.changes.all == [.outOfStock(itemId: 1)])
        #expect(caughtUp.bag.items.map(\.id) == [2])
    }

    @Test("A bag emptied by the shop is empty, and says why")
    func everythingOutOfStock() {
        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            inStock: [1: false, 2: false]
        )

        #expect(caughtUp.bag.isEmpty)
        #expect(caughtUp.bag.total.cents == 0)
        #expect(caughtUp.changes.removals.map(\.itemId).sorted() == [1, 2])
    }

    @Test("Removals and price changes are kept apart, because they are told apart")
    func changesAreSeparable() {
        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            prices: [2: 59.99], inStock: [1: false, 2: true]
        )

        #expect(caughtUp.changes.removals == [.outOfStock(itemId: 1)])
        #expect(caughtUp.changes.priceChanges == [.priceWentUp(itemId: 2, from: 49.99, to: 59.99)])
        #expect(caughtUp.bag.items.map(\.id) == [2])
    }

    @Test("A shopper away a long time hears about everything that moved")
    func manyChangesAtOnce() {
        let bag = Bag(items: [
            BagItem(id: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
            BagItem(id: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: Date(timeIntervalSince1970: 1)),
            BagItem(id: 3, quantity: 1, lastKnownPrice: 19.99, dateAdded: Date(timeIntervalSince1970: 2)),
            BagItem(id: 4, quantity: 1, lastKnownPrice: 5.99, dateAdded: .now)
        ])

        let caughtUp = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            prices: [1: 12.99, 2: 39.99, 3: 19.99],
            inStock: [1: true, 2: false, 3: true, 4: false]
        )

        #expect(caughtUp.changes.removals.map(\.itemId).sorted() == [2, 4])
        #expect(caughtUp.changes.priceChanges == [.priceWentUp(itemId: 1, from: 9.99, to: 12.99)])
        #expect(caughtUp.bag.items.map(\.id) == [3, 1])
    }

    @Test("Catching up an empty bag is a quiet no-op")
    func emptyBag() {
        let caughtUp = BagReconciliation.reconcile(bag: Bag(), changes: BagChanges(), inStock: [1: false])

        #expect(caughtUp.bag.isEmpty)
        #expect(caughtUp.changes.isEmpty)
    }
}

/// A shopper who never looks is owed the whole story, not the last instalment.
@Suite("Changes that pile up while nobody is looking")
struct PendingChangeTests {

    private let bag = Bag(items: [BagItem(id: 1, quantity: 1, lastKnownPrice: 10)])

    private func reconcile(
        _ state: (bag: Bag, changes: BagChanges),
        prices: [Int: Double] = [:],
        inStock: [Int: Bool] = [:]
    ) -> (bag: Bag, changes: BagChanges) {
        BagReconciliation.reconcile(
            bag: state.bag, changes: state.changes,
            prices: prices, inStock: inStock
        )
    }

    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() {
        let once = reconcile((bag, BagChanges()), prices: [1: 12])
        let twice = reconcile(once, prices: [1: 15])

        #expect(twice.changes.priceChanges == [.priceWentUp(itemId: 1, from: 10, to: 15)])
        #expect(twice.bag.total.cents == 1500)
    }

    @Test("A price that moves up and back down again is no longer news")
    func moveAndMoveBack() {
        let back = reconcile(reconcile((bag, BagChanges()), prices: [1: 12]), prices: [1: 10])

        #expect(back.changes.isEmpty)
        #expect(back.bag.total.cents == 1000)
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() {
        let below = reconcile(reconcile((bag, BagChanges()), prices: [1: 12]), prices: [1: 8])

        #expect(below.changes.priceChanges == [.priceWentDown(itemId: 1, from: 10, to: 8)])
    }

    @Test("A pending price change survives a catch-up that did not cover that product")
    func survivesAPartialLookup() {
        let moved = reconcile((bag, BagChanges()), prices: [1: 12])

        let partial = reconcile(moved)

        #expect(partial.changes.priceChanges == [.priceWentUp(itemId: 1, from: 10, to: 12)])
    }

    @Test("Being told twice that something has gone is still one warning")
    func removalIsNotRepeated() {
        let gone = reconcile((bag, BagChanges()), inStock: [1: false])
        let again = reconcile(gone, inStock: [1: false])

        #expect(again.changes.removals == [.outOfStock(itemId: 1)])
    }

    @Test("A warning about something that has left the bag outlives the line it refers to")
    func removalWarningSurvives() {
        // The whole point is to explain a bag that is now shorter, so it cannot be
        // dropped for the very reason it exists.
        let gone = reconcile((bag, BagChanges()), inStock: [1: false])

        #expect(gone.bag.isEmpty)
        #expect(gone.changes.removals == [.outOfStock(itemId: 1)])
    }

    @Test("Saying it has been seen clears it, and the next move starts from there")
    func acknowledging() {
        let moved = reconcile((bag, BagChanges()), prices: [1: 12])
        let seen = (moved.bag, moved.changes.acknowledging(itemId: 1))

        #expect(seen.1.isEmpty)
        #expect(reconcile(seen, prices: [1: 15]).changes.priceChanges
            == [.priceWentUp(itemId: 1, from: 12, to: 15)])
    }

    @Test("Saying one product has been seen leaves the others still waiting")
    func acknowledgingOne() {
        let both = reconcile(
            (Bag(items: [
                BagItem(id: 1, lastKnownPrice: 10, dateAdded: .distantPast),
                BagItem(id: 2, lastKnownPrice: 20, dateAdded: .now)
            ]), BagChanges()),
            inStock: [1: false, 2: false]
        )

        #expect(both.changes.acknowledging(itemId: 2).removals == [.outOfStock(itemId: 1)])
    }
}

/// `Bag` and `BagChanges` are written one after the other. Deciding what is worth saying
/// when they are read means a pair that has drifted apart — a crash between the two
/// writes, or a product chosen again — corrects itself rather than showing nonsense.
@Suite("Which notices still make sense")
struct ApplicableChangesTests {

    private let inTheBag = Bag(items: [BagItem(id: 1, lastKnownPrice: 10)])

    @Test("A price notice about something in the bag stands")
    func priceNoticeForAPresentLine() {
        let changes = BagChanges([.priceWentUp(itemId: 1, from: 10, to: 12)])

        #expect(BagReconciliation.applicable(changes, to: inTheBag) == changes)
    }

    @Test("A price notice about something no longer in the bag is news about nothing")
    func priceNoticeForAnAbsentLine() {
        let changes = BagChanges([.priceWentUp(itemId: 1, from: 10, to: 12)])

        #expect(BagReconciliation.applicable(changes, to: Bag()).isEmpty)
    }

    @Test("A removal notice about something no longer in the bag stands")
    func removalNoticeForAnAbsentLine() {
        let changes = BagChanges([.outOfStock(itemId: 1)])

        #expect(BagReconciliation.applicable(changes, to: Bag()) == changes)
    }

    @Test("A removal notice about something the shopper has chosen again is spent")
    func removalNoticeForAPresentLine() {
        let changes = BagChanges([.outOfStock(itemId: 1)])

        #expect(BagReconciliation.applicable(changes, to: inTheBag).isEmpty)
    }

    @Test("A pair that has drifted apart keeps only the half that still holds")
    func mixedNotices() {
        let bag = Bag(items: [BagItem(id: 1, lastKnownPrice: 10)])
        let changes = BagChanges([
            .priceWentUp(itemId: 1, from: 10, to: 12),   // in the bag: stands
            .priceWentUp(itemId: 2, from: 20, to: 25),   // gone: nonsense
            .outOfStock(itemId: 3),                      // gone: stands
            .outOfStock(itemId: 1)                       // back in the bag: spent
        ])

        let worthSaying = BagReconciliation.applicable(changes, to: bag)

        #expect(worthSaying.priceChanges == [.priceWentUp(itemId: 1, from: 10, to: 12)])
        #expect(worthSaying.removals == [.outOfStock(itemId: 3)])
    }
}
