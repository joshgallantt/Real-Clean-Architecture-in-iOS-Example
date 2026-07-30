import Foundation
import Testing
import Product
import Bag

/// A shopper comes back to a bag they filled a while ago. Prices have moved, some things
/// have sold out, and they are owed an explanation for both.
@Suite("Coming back to a bag after the shop has moved on")
struct ComingBackToTheBagTests {

    private let bag = Bag(items: [
        BagItem(productId: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
        BagItem(productId: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: .now)
    ])

    @Test("A shop asking the same prices has nothing to tell anyone")
    func nothingChanged() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopSells(1, at: 9.99), shopSells(2, at: 49.99)]
        )

        #expect(upToDate.bag == bag)
        #expect(upToDate.changes.isEmpty)
    }

    @Test("A price that went up is charged, and the shopper is told before they wonder")
    func priceWentUp() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopSells(1, at: 12.99)]
        )

        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: 1, from: 9.99, to: 12.99)])
        #expect(upToDate.bag.total.cents == 4999 + 2598)
    }

    @Test("A price that came down is passed on — the shopper should get the better one")
    func priceWentDown() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopSells(1, at: 4.99)]
        )

        #expect(upToDate.changes.priceMoves == [.priceWentDown(productId: 1, from: 9.99, to: 4.99)])
        #expect(upToDate.bag.total.cents == 4999 + 998)
    }

    @Test("Something the shop cannot supply leaves the bag, and the shopper is told it went")
    func soldOut() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopHasSoldOutOf(1)]
        )

        // A bag is what the shopper is going to buy, and a line that cannot be bought
        // does not belong in it.
        #expect(upToDate.bag.items.map(\.productId) == [2])
        #expect(upToDate.changes.noLongerAvailable == [.noLongerAvailable(productId: 1)])
        #expect(upToDate.bag.total.cents == 4999)
    }

    @Test("What something's price did on the way out is not worth saying")
    func soldOutAndRepriced() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [Product.fixture(id: 1, price: 12.99, stock: 0)]
        )

        // Telling a shopper what something costs and that they cannot have it is two
        // messages where one will do.
        #expect(upToDate.changes.all == [.noLongerAvailable(productId: 1)])
    }

    @Test("A product the shop was not asked about is left exactly as it was")
    func notAskedAbout() {
        // A lookup that covered part of the bag, or failed for one product, must never
        // read as "that product is gone".
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopSells(2, at: 49.99)]
        )

        #expect(upToDate.bag == bag)
        #expect(upToDate.changes.isEmpty)
    }

    @Test("A bag the shop has emptied is empty, and says why")
    func everythingSoldOut() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopHasSoldOutOf(1), shopHasSoldOutOf(2)]
        )

        #expect(upToDate.bag.isEmpty)
        #expect(upToDate.bag.total.cents == 0)
        #expect(upToDate.changes.noLongerAvailable.map(\.productId).sorted() == [1, 2])
    }

    @Test("Price moves and disappearances are kept apart, because they are told apart")
    func twoKindsOfNews() {
        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [shopHasSoldOutOf(1), shopSells(2, at: 59.99)]
        )

        #expect(upToDate.changes.noLongerAvailable == [.noLongerAvailable(productId: 1)])
        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: 2, from: 49.99, to: 59.99)])
        #expect(upToDate.bag.items.map(\.productId) == [2])
    }

    @Test("A shopper away a long time hears about everything that moved")
    func aLotHasHappened() {
        let bag = Bag(items: [
            BagItem(productId: 1, quantity: 2, lastKnownPrice: 9.99, dateAdded: .distantPast),
            BagItem(productId: 2, quantity: 1, lastKnownPrice: 49.99, dateAdded: Date(timeIntervalSince1970: 1)),
            BagItem(productId: 3, quantity: 1, lastKnownPrice: 19.99, dateAdded: Date(timeIntervalSince1970: 2)),
            BagItem(productId: 4, quantity: 1, lastKnownPrice: 5.99, dateAdded: .now)
        ])

        let upToDate = BagReconciliation.reconcile(
            bag: bag, changes: BagChanges(),
            against: [
                shopSells(1, at: 12.99),
                shopHasSoldOutOf(2),
                shopSells(3, at: 19.99),
                shopHasSoldOutOf(4)
            ]
        )

        #expect(upToDate.changes.noLongerAvailable.map(\.productId).sorted() == [2, 4])
        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: 1, from: 9.99, to: 12.99)])
        #expect(upToDate.bag.items.map(\.productId) == [3, 1])
    }

    @Test("An empty bag has nothing to catch up on")
    func emptyBag() {
        let upToDate = BagReconciliation.reconcile(
            bag: Bag(), changes: BagChanges(),
            against: [shopHasSoldOutOf(1)]
        )

        #expect(upToDate.bag.isEmpty)
        #expect(upToDate.changes.isEmpty)
    }
}

/// A shopper who does not read the notice is owed the whole story next time, not the last
/// instalment of it.
@Suite("News that piles up while nobody is looking")
struct NewsThatPilesUpTests {

    private let bag = Bag(items: [BagItem(productId: 1, quantity: 1, lastKnownPrice: 10)])

    private func catchUp(
        _ state: (bag: Bag, changes: BagChanges),
        against products: [Product]
    ) -> (bag: Bag, changes: BagChanges) {
        BagReconciliation.reconcile(bag: state.bag, changes: state.changes, against: products)
    }

    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() {
        let once = catchUp((bag, BagChanges()), against: [shopSells(1, at: 12)])
        let twice = catchUp(once, against: [shopSells(1, at: 15)])

        #expect(twice.changes.priceMoves == [.priceWentUp(productId: 1, from: 10, to: 15)])
        #expect(twice.bag.total.cents == 1500)
    }

    @Test("A price that goes up and comes back down is no longer news")
    func moveAndMoveBack() {
        let up = catchUp((bag, BagChanges()), against: [shopSells(1, at: 12)])
        let back = catchUp(up, against: [shopSells(1, at: 10)])

        #expect(back.changes.isEmpty)
        #expect(back.bag.total.cents == 1000)
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() {
        let up = catchUp((bag, BagChanges()), against: [shopSells(1, at: 12)])
        let below = catchUp(up, against: [shopSells(1, at: 8)])

        #expect(below.changes.priceMoves == [.priceWentDown(productId: 1, from: 10, to: 8)])
    }

    @Test("News survives a catch-up that did not cover that product")
    func survivesAPartialLookup() {
        let moved = catchUp((bag, BagChanges()), against: [shopSells(1, at: 12)])

        let partial = catchUp(moved, against: [])

        #expect(partial.changes.priceMoves == [.priceWentUp(productId: 1, from: 10, to: 12)])
    }

    @Test("Being told twice that something has gone is still one piece of news")
    func goneIsNotRepeated() {
        let gone = catchUp((bag, BagChanges()), against: [shopHasSoldOutOf(1)])
        let again = catchUp(gone, against: [shopHasSoldOutOf(1)])

        #expect(again.changes.noLongerAvailable == [.noLongerAvailable(productId: 1)])
    }

    @Test("News about something that has left the bag outlives the line it refers to")
    func newsOutlivesTheLine() {
        // The whole point is to explain a bag that is now shorter, so it cannot be
        // dropped for the very reason it exists.
        let gone = catchUp((bag, BagChanges()), against: [shopHasSoldOutOf(1)])

        #expect(gone.bag.isEmpty)
        #expect(gone.changes.noLongerAvailable == [.noLongerAvailable(productId: 1)])
    }

    @Test("Saying it has been seen clears it, and the next move starts from there")
    func seenIt() {
        let moved = catchUp((bag, BagChanges()), against: [shopSells(1, at: 12)])
        let seen = (moved.bag, moved.changes.acknowledging(productId: 1))

        #expect(seen.1.isEmpty)
        #expect(catchUp(seen, against: [shopSells(1, at: 15)]).changes.priceMoves
            == [.priceWentUp(productId: 1, from: 12, to: 15)])
    }

    @Test("Saying one product has been seen leaves the others still waiting")
    func seenOneOfTwo() {
        let both = catchUp(
            (Bag(items: [
                BagItem(productId: 1, lastKnownPrice: 10, dateAdded: .distantPast),
                BagItem(productId: 2, lastKnownPrice: 20, dateAdded: .now)
            ]), BagChanges()),
            against: [shopHasSoldOutOf(1), shopHasSoldOutOf(2)]
        )

        #expect(both.changes.acknowledging(productId: 2).noLongerAvailable
            == [.noLongerAvailable(productId: 1)])
    }
}

/// `Bag` and `BagChanges` are written one after the other. Deciding what is worth saying
/// when they are read means a pair that has drifted apart — a crash between the two
/// writes, or a product chosen again — corrects itself rather than showing nonsense.
@Suite("Which news still holds")
struct WorthTellingTests {

    private let inTheBag = Bag(items: [BagItem(productId: 1, lastKnownPrice: 10)])

    @Test("A price move about something in the bag stands")
    func priceMoveForSomethingPresent() {
        let changes = BagChanges([.priceWentUp(productId: 1, from: 10, to: 12)])

        #expect(BagReconciliation.worthTelling(changes, about: inTheBag) == changes)
    }

    @Test("A price move about something no longer in the bag is news about nothing")
    func priceMoveForSomethingAbsent() {
        let changes = BagChanges([.priceWentUp(productId: 1, from: 10, to: 12)])

        #expect(BagReconciliation.worthTelling(changes, about: Bag()).isEmpty)
    }

    @Test("News that something has gone stands while it is gone")
    func goneAndStillGone() {
        let changes = BagChanges([.noLongerAvailable(productId: 1)])

        #expect(BagReconciliation.worthTelling(changes, about: Bag()) == changes)
    }

    @Test("News that something has gone is spent once the shopper chooses it again")
    func goneButChosenAgain() {
        let changes = BagChanges([.noLongerAvailable(productId: 1)])

        #expect(BagReconciliation.worthTelling(changes, about: inTheBag).isEmpty)
    }

    @Test("A pair that has drifted apart keeps only the half that still holds")
    func mixedNews() {
        let changes = BagChanges([
            .priceWentUp(productId: 1, from: 10, to: 12),   // in the bag: stands
            .priceWentUp(productId: 2, from: 20, to: 25),   // gone: nonsense
            .noLongerAvailable(productId: 3),               // gone: stands
            .noLongerAvailable(productId: 1)                // back in the bag: spent
        ])

        let worthSaying = BagReconciliation.worthTelling(changes, about: inTheBag)

        #expect(worthSaying.priceMoves == [.priceWentUp(productId: 1, from: 10, to: 12)])
        #expect(worthSaying.noLongerAvailable == [.noLongerAvailable(productId: 3)])
    }
}

// MARK: - What the shop says

private func shopSells(_ productId: Int, at price: Double) -> Product {
    .fixture(id: productId, price: price, stock: 10)
}

private func shopHasSoldOutOf(_ productId: Int) -> Product {
    .fixture(id: productId, price: 1, stock: 0)
}

private extension Product {
    static func fixture(id: Int, price: Double, stock: Int) -> Product {
        Product(
            id: id,
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: price,
            discountPercentage: 0,
            rating: 4.5,
            stock: stock,
            willRestock: true,
            brand: "Acme",
            thumbnail: "",
            images: []
        )
    }
}
