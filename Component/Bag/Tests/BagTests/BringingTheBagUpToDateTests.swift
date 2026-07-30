import Combine
import Foundation
import Testing
import Bag
import Money
import Product

/// A shopper comes back to a bag they filled a while ago. Prices have moved, some things
/// have sold out, some are down to the last few, and they are owed an explanation for all
/// of it.
///
/// Driven through the use case, not a static helper behind it. Catching up is application
/// work — read both, decide, write both back — and the thing worth proving is that the use
/// case does it, because that is all any caller can reach.
@MainActor
@Suite("Coming back to a bag after the shop has moved on")
struct ComingBackToTheBagTests {

    private let bag = Bag(items: [
        item(1, quantity: 2, price: 9.99, addedAt: .distantPast),
        item(2, quantity: 1, price: 49.99, addedAt: .now)
    ])

    @Test("A shop asking the same prices has nothing to tell anyone")
    func nothingChanged() {
        let upToDate = catchUp(bag, against: [shopSells(1, at: 9.99), shopSells(2, at: 49.99)])

        #expect(upToDate.bag == bag)
        #expect(upToDate.changes.isEmpty)
    }

    @Test("A bag with nothing to correct is not saved at all")
    func nothingToSave() {
        let repository = InMemoryBagRepository(bag)
        let bringUpToDate = DefaultBringBagUpToDateUseCase(repository: repository)

        bringUpToDate(against: [shopSells(1, at: 9.99), shopSells(2, at: 49.99)])

        // Saving here would wake everything watching the bag for nothing, on a screen that
        // does this every time it appears.
        #expect(repository.saved.isEmpty)
    }

    @Test("A price that went up is charged, and the shopper is told before they wonder")
    func priceWentUp() {
        let upToDate = catchUp(bag, against: [shopSells(1, at: 12.99)])

        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(upToDate.bag.total == usd(49.99 + 25.98))
    }

    @Test("A price that came down is passed on — the shopper should get the better one")
    func priceWentDown() {
        let upToDate = catchUp(bag, against: [shopSells(1, at: 4.99)])

        #expect(upToDate.changes.priceMoves == [.priceWentDown(productId: pid(1), from: usd(9.99), to: usd(4.99))])
        #expect(upToDate.bag.total == usd(49.99 + 9.98))
    }

    @Test("Something the shop cannot supply leaves the bag, and the shopper is told it went")
    func soldOut() {
        let upToDate = catchUp(bag, against: [shopHasSoldOutOf(1)])

        // A bag is what the shopper is going to buy, and a line that cannot be bought
        // does not belong in it.
        #expect(upToDate.bag.items.map(\.productId) == [pid(2)])
        #expect(upToDate.changes.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(upToDate.bag.total == usd(49.99))
    }

    @Test("Something the shop has stopped selling goes the same way as something sold out")
    func discontinued() {
        let upToDate = catchUp(bag, against: [shopHasDiscontinued(1)])

        #expect(upToDate.bag.items.map(\.productId) == [pid(2)])
        #expect(upToDate.changes.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("What something's price did on the way out is not worth saying")
    func soldOutAndRepriced() {
        let upToDate = catchUp(
            bag,
            against: [ShopSays(productId: pid(1), price: usd(12.99), availability: .outOfStock)]
        )

        // Telling a shopper what something costs and that they cannot have it is two
        // messages where one will do.
        #expect(upToDate.changes.all == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("A product the shop was not asked about is left exactly as it was")
    func notAskedAbout() {
        // A lookup that covered part of the bag, or failed for one product, must never
        // read as "that product is gone".
        let upToDate = catchUp(bag, against: [shopSells(2, at: 49.99)])

        #expect(upToDate.bag == bag)
        #expect(upToDate.changes.isEmpty)
    }

    @Test("A bag the shop has emptied is empty, and says why")
    func everythingSoldOut() {
        let upToDate = catchUp(bag, against: [shopHasSoldOutOf(1), shopHasSoldOutOf(2)])

        #expect(upToDate.bag.isEmpty)
        #expect(upToDate.bag.total == nil)
        #expect(Set(upToDate.changes.noLongerAvailable.map(\.productId)) == [pid(1), pid(2)])
    }

    @Test("Price moves and disappearances are kept apart, because they are told apart")
    func twoKindsOfNews() {
        let upToDate = catchUp(bag, against: [shopHasSoldOutOf(1), shopSells(2, at: 59.99)])

        #expect(upToDate.changes.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: pid(2), from: usd(49.99), to: usd(59.99))])
        #expect(upToDate.bag.items.map(\.productId) == [pid(2)])
    }

    @Test("A shopper away a long time hears about everything that moved")
    func aLotHasHappened() {
        let bag = Bag(items: [
            item(1, quantity: 2, price: 9.99, addedAt: .distantPast),
            item(2, quantity: 1, price: 49.99, addedAt: Date(timeIntervalSince1970: 1)),
            item(3, quantity: 1, price: 19.99, addedAt: Date(timeIntervalSince1970: 2)),
            item(4, quantity: 1, price: 5.99, addedAt: .now)
        ])

        let upToDate = catchUp(bag, against: [
            shopSells(1, at: 12.99),
            shopHasSoldOutOf(2),
            shopSells(3, at: 19.99),
            shopHasSoldOutOf(4)
        ])

        #expect(Set(upToDate.changes.noLongerAvailable.map(\.productId)) == [pid(2), pid(4)])
        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(upToDate.bag.items.map(\.productId) == [pid(3), pid(1)])
    }

    @Test("An empty bag has nothing to catch up on")
    func emptyBag() {
        let upToDate = catchUp(Bag(), against: [shopHasSoldOutOf(1)])

        #expect(upToDate.bag.isEmpty)
        #expect(upToDate.changes.isEmpty)
    }
}

/// A shopper cannot buy five of something the shop has two of. Finding that out at checkout
/// is finding out too late, and a count that quietly changes on its own is the thing the
/// removal notice already exists to avoid.
@MainActor
@Suite("Asking for more than the shop has")
struct MoreThanTheShopHasTests {

    @Test("A line comes down to what the shop can actually supply")
    func quantityIsCapped() {
        let upToDate = catchUp(
            Bag(items: [item(1, quantity: 5, price: 10)]),
            against: [shopSells(1, at: 10, remaining: 2)]
        )

        #expect(upToDate.bag.quantity(of: pid(1)) == 2)
        #expect(upToDate.bag.total == usd(20))
    }

    @Test("Cutting a line down is said out loud, not left as a number that changed itself")
    func shortageIsReported() {
        let upToDate = catchUp(
            Bag(items: [item(1, quantity: 5, price: 10)]),
            against: [shopSells(1, at: 10, remaining: 2)]
        )

        #expect(upToDate.changes.shortages == [.onlySomeLeft(productId: pid(1), available: 2)])
    }

    @Test("Asking for exactly what the shop has is not a shortage")
    func exactlyEnough() {
        let upToDate = catchUp(
            Bag(items: [item(1, quantity: 2, price: 10)]),
            against: [shopSells(1, at: 10, remaining: 2)]
        )

        #expect(upToDate.bag.quantity(of: pid(1)) == 2)
        #expect(upToDate.changes.isEmpty)
    }

    @Test("A line that is both short and repriced is both, because they are two facts")
    func shortAndRepriced() {
        let upToDate = catchUp(
            Bag(items: [item(1, quantity: 5, price: 10)]),
            against: [shopSells(1, at: 12, remaining: 2)]
        )

        #expect(upToDate.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
        #expect(upToDate.changes.shortages == [.onlySomeLeft(productId: pid(1), available: 2)])
        #expect(upToDate.bag.total == usd(24))
    }

    @Test("A shortage next to a price move does not swallow the price the shopper knew")
    func shortageDoesNotHideThePriceTheyKnew() {
        // Both notices are about the same product, and only one of them carries a price.
        // Reading the wrong one would restart the price move from nothing.
        let once = catchUp(
            Bag(items: [item(1, quantity: 5, price: 10)]),
            against: [shopSells(1, at: 12, remaining: 2)]
        )

        let twice = catchUp(once.bag, changes: once.changes, against: [shopSells(1, at: 15, remaining: 2)])

        #expect(twice.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
    }
}

/// A shopper who does not read the notice is owed the whole story next time, not the last
/// instalment of it.
@MainActor
@Suite("News that piles up while nobody is looking")
struct NewsThatPilesUpTests {

    private let bag = Bag(items: [item(1, quantity: 1, price: 10)])

    @Test("A price that moves twice before the shopper looks reads as one move from what they knew")
    func twoMovesReadAsOne() {
        let once = catchUp(bag, against: [shopSells(1, at: 12)])
        let twice = catchUp(once.bag, changes: once.changes, against: [shopSells(1, at: 15)])

        #expect(twice.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(15))])
        #expect(twice.bag.total == usd(15))
    }

    @Test("A price that goes up and comes back down is no longer news")
    func moveAndMoveBack() {
        let up = catchUp(bag, against: [shopSells(1, at: 12)])
        let back = catchUp(up.bag, changes: up.changes, against: [shopSells(1, at: 10)])

        #expect(back.changes.isEmpty)
        #expect(back.bag.total == usd(10))
    }

    @Test("A price that crosses back over reverses which way it is reported")
    func moveUpThenBelow() {
        let up = catchUp(bag, against: [shopSells(1, at: 12)])
        let below = catchUp(up.bag, changes: up.changes, against: [shopSells(1, at: 8)])

        #expect(below.changes.priceMoves == [.priceWentDown(productId: pid(1), from: usd(10), to: usd(8))])
    }

    @Test("News survives a catch-up that did not cover that product")
    func survivesAPartialLookup() {
        let moved = catchUp(bag, against: [shopSells(1, at: 12)])

        let partial = catchUp(moved.bag, changes: moved.changes, against: [])

        #expect(partial.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
    }

    @Test("Being told twice that something has gone is still one piece of news")
    func goneIsNotRepeated() {
        let gone = catchUp(bag, against: [shopHasSoldOutOf(1)])
        let again = catchUp(gone.bag, changes: gone.changes, against: [shopHasSoldOutOf(1)])

        #expect(again.changes.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("News about something that has left the bag outlives the line it refers to")
    func newsOutlivesTheLine() {
        // The whole point is to explain a bag that is now shorter, so it cannot be
        // dropped for the very reason it exists.
        let gone = catchUp(bag, against: [shopHasSoldOutOf(1)])

        #expect(gone.bag.isEmpty)
        #expect(gone.changes.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
    }

    @Test("Saying it has been seen clears it, and the next move starts from there")
    func seenIt() {
        let moved = catchUp(bag, against: [shopSells(1, at: 12)])
        let seenChanges = moved.changes.acknowledging(productId: pid(1))

        #expect(seenChanges.isEmpty)

        let next = catchUp(moved.bag, changes: seenChanges, against: [shopSells(1, at: 15)])
        #expect(next.changes.priceMoves == [.priceWentUp(productId: pid(1), from: usd(12), to: usd(15))])
    }

    @Test("Saying one product has been seen leaves the others still waiting")
    func seenOneOfTwo() {
        let both = catchUp(
            Bag(items: [
                item(1, price: 10, addedAt: .distantPast),
                item(2, price: 20, addedAt: .now)
            ]),
            against: [shopHasSoldOutOf(1), shopHasSoldOutOf(2)]
        )

        #expect(both.changes.acknowledging(productId: pid(2)).noLongerAvailable
            == [.noLongerAvailable(productId: pid(1))])
    }
}

/// The bag and the notices are written one after the other. Deciding what is worth saying
/// when they are read means a pair that has drifted apart — a crash between the two writes,
/// or a product chosen again — corrects itself rather than showing nonsense.
///
/// Asserted through the publisher a screen actually subscribes to, because that is the point:
/// a screen is handed news it can show as-is and is never trusted to apply the rule itself.
@MainActor
@Suite("Which news still holds")
struct WorthTellingTests {

    private let inTheBag = Bag(items: [item(1, price: 10)])

    @Test("A price move about something in the bag stands")
    func priceMoveForSomethingPresent() {
        let changes = BagChanges([.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])

        #expect(newsPublished(changes, about: inTheBag) == changes)
    }

    @Test("A price move about something no longer in the bag is news about nothing")
    func priceMoveForSomethingAbsent() {
        let changes = BagChanges([.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])

        #expect(newsPublished(changes, about: Bag()).isEmpty)
    }

    @Test("A shortage stands while the line is there and is nonsense once it is gone")
    func shortageFollowsTheLine() {
        let changes = BagChanges([.onlySomeLeft(productId: pid(1), available: 2)])

        #expect(newsPublished(changes, about: inTheBag) == changes)
        #expect(newsPublished(changes, about: Bag()).isEmpty)
    }

    @Test("News that something has gone stands while it is gone")
    func goneAndStillGone() {
        let changes = BagChanges([.noLongerAvailable(productId: pid(1))])

        #expect(newsPublished(changes, about: Bag()) == changes)
    }

    @Test("News that something has gone is spent once the shopper chooses it again")
    func goneButChosenAgain() {
        let changes = BagChanges([.noLongerAvailable(productId: pid(1))])

        #expect(newsPublished(changes, about: inTheBag).isEmpty)
    }

    @Test("A pair that has drifted apart keeps only the half that still holds")
    func mixedNews() {
        let changes = BagChanges([
            .priceWentUp(productId: pid(1), from: usd(10), to: usd(12)),   // in the bag: stands
            .priceWentUp(productId: pid(2), from: usd(20), to: usd(25)),   // gone: nonsense
            .noLongerAvailable(productId: pid(3)),                         // gone: stands
            .noLongerAvailable(productId: pid(1))                          // back in the bag: spent
        ])

        let worthSaying = newsPublished(changes, about: inTheBag)

        #expect(worthSaying.priceMoves == [.priceWentUp(productId: pid(1), from: usd(10), to: usd(12))])
        #expect(worthSaying.noLongerAvailable == [.noLongerAvailable(productId: pid(3))])
    }

    private func newsPublished(_ changes: BagChanges, about bag: Bag) -> BagChanges {
        let repository = InMemoryBagRepository(bag, changes: changes)
        let observe = DefaultObserveBagChangesUseCase(repository: repository)

        var received = BagChanges()
        let cancellable = observe().sink { received = $0 }
        cancellable.cancel()
        return received
    }
}

// MARK: -

/// Runs the real use case over a real in-memory repository and hands back what it kept.
@MainActor
private func catchUp(
    _ bag: Bag,
    changes: BagChanges = BagChanges(),
    against shopSays: [ShopSays]
) -> (bag: Bag, changes: BagChanges) {
    let repository = InMemoryBagRepository(bag, changes: changes)
    let bringUpToDate = DefaultBringBagUpToDateUseCase(repository: repository)

    bringUpToDate(against: shopSays)

    return (repository.bag, repository.changes)
}
