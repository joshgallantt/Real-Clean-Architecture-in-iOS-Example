import MoneyTestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import SettingsTestSupport
import Testing
import Tracking
import TrackingTestSupport
import Bag
import Money
import Product
@testable import BagUITestSupport
@testable import BagUI

@MainActor
@Suite("Looking in the bag", .serialized)
/// What a shopper is shown when they open their bag: lines that are true today, and one list of
/// what is different from the last time they looked. The use cases under the screen are the real
/// ones; only where the bag is kept and what the shop answers are stood in for.
struct LookingInTheBagTests {
    private let navigation = SpyBagNavigation()

    private func makeViewModel(shop: FakeShop) -> BagScreenViewModel {
        BagScreenViewModel(
            navigation: navigation,
            observeBag: shop.observeBag,
            setBagItem: shop.setBagItem,
            checkBag: shop.checkBag,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    private func makeShop(
        items: [BagItem] = [bagItem(1, price: 9.99)],
        catalog: [Product] = [.fixture(id: 1)]
    ) -> FakeShop {
        FakeShop(bag: Bag(items: items), catalog: catalog)
    }

    // MARK: - Asking the shop

    @Test("Opening the bag asks the shop about everything in it")
    func opening() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(shop.lookups == [[pid(1)]])
    }

    @Test("Opening it again asks again — coming back after a while is the whole point")
    func openingAgain() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(shop.lookups == [[pid(1)], [pid(1)]])
    }

    @Test("Changing how many asks again")
    func changingQuantityAsks() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)
        await viewModel.inFlight?.value

        #expect(shop.lookups.count == 2)
        #expect(shop.currentBag.quantity(of: pid(1)) == 3)
    }

    @Test("Taking something out asks again")
    func removingAsks() async {
        let shop = makeShop(
            items: [
                bagItem(1, price: 9.99, addedAt: .distantPast),
                bagItem(2, price: 5, addedAt: .now)
            ],
            catalog: [.fixture(id: 1), .fixture(id: 2, price: 5)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didSwipeToDelete(productId: pid(2), in: inTheBag)
        await viewModel.inFlight?.value

        #expect(shop.currentBag.items.map(\.id) == [pid(1)])
        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(shop.lookups.count == 2)
    }

    @Test("Rows render from the bag before the shop answers, and the total never waits")
    func rowsDoNotWaitForTheCatalog() async {
        let shop = makeShop()
        shop.holdTheNextLookup()
        let viewModel = makeViewModel(shop: shop)

        let appearing = Task { await viewModel.onAppear() }
        await shop.untilAsked()

        #expect(viewModel.rows.map(\.id) == [pid(1)])
        #expect(viewModel.rows.first?.product?.title == nil)
        #expect(viewModel.total == usd(9.99))

        shop.answerNow()
        await appearing.value
    }

    @Test("Names and pictures arrive once the shop answers")
    func namesArriveLater() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.rows.first?.product?.title == "Product 1")
    }

    // MARK: - The lines show the truth

    @Test("A shop asking the same prices has nothing to tell, and the bag is drawn as it was kept")
    func nothingChanged() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.hasChanges == false)
        #expect(viewModel.rows.map(\.lineTotal) == [usd(9.99)])
    }

    @Test("A line shows today's price, and the total is what the lines add up to")
    func linesShowTodaysPrice() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 2, price: 9.99)],
            catalog: [.fixture(id: 1, price: 12.99)]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.rows.map(\.unitPrice) == [usd(12.99)])
        #expect(viewModel.rows.map(\.lineTotal) == [usd(25.98)])
        #expect(viewModel.total == usd(25.98))
    }

    @Test("A line shows no more than the shop has left")
    func linesAreCappedToWhatIsLeft() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 5, price: 10)],
            catalog: [.fixture(id: 1, price: 10, availability: .inStock(remaining: 2))]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.rows.map(\.quantity) == [2])
        #expect(viewModel.total == usd(20))
        #expect(viewModel.itemCountSummary == "2 items")
    }

    @Test("Something sold out is not a line, and is listed as a change")
    func soldOutIsNotALine() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isEmpty)
        #expect(viewModel.changes.map(\.id) == [.soldOut(productId: pid(1))])
    }

    @Test("Something the shop no longer answers about leaves quietly, with nothing said about it")
    func stoppedSellingSaysNothing() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.changes.map(\.id) == [.soldOut(productId: pid(1))])
        #expect(viewModel.isEmpty)
    }

    /// A shop that answers and describes nothing has told the bag something. Silence about a
    /// product it was *asked* about is the only way a shop says it has stopped selling one, so the
    /// line goes.
    ///
    /// A shop that could not be reached at all is the other case, below, and it must not do this —
    /// a bag emptied by a dropped connection would be the worst bug on this screen.
    @Test("A shop that answers and describes nothing has stopped selling all of it")
    func answeringWithNothingMeansStopped() async {
        let shop = makeShop(catalog: [])
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.isEmpty)
        #expect(viewModel.hasChanges == false)
    }

    @Test("A shop that cannot be reached changes nothing and reports nothing")
    func aShopThatCannotBeReachedChangesNothing() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        shop.cannotBeReached = true
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()
        viewModel.didDisappear()

        #expect(viewModel.hasChanges == false)
        #expect(viewModel.total == usd(9.99))
        #expect(shop.currentBag.total == usd(9.99))
    }

    @Test("Losing the shop part-way through a visit does not bring back what it had said was sold out")
    func losingTheShopKeepsWhatWasKnown() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, availability: .outOfStock), .fixture(id: 2, price: 5)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        shop.cannotBeReached = true
        viewModel.didChangeQuantity(productId: pid(2), quantity: 2, in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.rows.map(\.id) == [pid(2)])
        #expect(viewModel.rows.map(\.quantity) == [2])
    }

    // MARK: - Changes since the bag was last viewed

    @Test("A row says the one thing that changed, in words or in two amounts")
    func whatARowSays() async {
        let shop = makeShop(
            items: [
                bagItem(1, price: 9.99, addedAt: Date(timeIntervalSince1970: 5)),
                bagItem(3, quantity: 4, price: 9.99, addedAt: Date(timeIntervalSince1970: 4)),
                bagItem(4, quantity: 3, price: 9.99, addedAt: Date(timeIntervalSince1970: 3)),
                bagItem(5, price: 5, addedAt: Date(timeIntervalSince1970: 2)),
                bagItem(6, price: 5, addedAt: Date(timeIntervalSince1970: 1))
            ],
            catalog: [
                .fixture(id: 1, availability: .outOfStock),
                .fixture(id: 3, availability: .inStock(remaining: 2)),
                .fixture(id: 4, availability: .inStock(remaining: 1)),
                .fixture(id: 5, price: 8),
                .fixture(id: 6, price: 4)
            ]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.changes.map(\.says) == [
            .soldOut("Sold out"),
            .howManyLeft("Only 2 left"),
            .howManyLeft("Only 1 left"),
            .priceMoved(BagChangeRow.PriceMove(was: usd(5).formatted(), now: usd(8).formatted(), isCheaper: false)),
            .priceMoved(BagChangeRow.PriceMove(was: usd(5).formatted(), now: usd(4).formatted(), isCheaper: true))
        ])
    }

    @Test("A line that is both dearer and short is listed twice, once for each")
    func twoChangesToOneLine() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 5, price: 10)],
            catalog: [.fixture(id: 1, price: 12, availability: .inStock(remaining: 2))]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.changes.map(\.id) == [
            .priceWentUp(productId: pid(1), from: usd(10), to: usd(12)),
            .onlySomeLeft(productId: pid(1), available: 2)
        ])
        #expect(viewModel.rows.map(\.lineTotal) == [usd(24)])
    }

    @Test("Every change says which product it is about, sold out or not")
    func changesAreNamed() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, availability: .outOfStock), .fixture(id: 2, price: 8)]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(Set(viewModel.changes.compactMap(\.product?.title)) == ["Product 1", "Product 2"])
    }

    @Test("A bag emptied by the shop still shows why, rather than looking like an empty bag")
    func emptiedByTheShopStillExplains() async {
        let shop = makeShop(catalog: [.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.isEmpty)
        #expect(viewModel.hasChanges)
    }

    // MARK: - A change is shown once

    @Test("Looking keeps nothing: the bag is not written until the shopper leaves")
    func lookingKeepsNothing() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.total == usd(12.99))
        #expect(shop.currentBag.total == usd(9.99))
    }

    @Test("While the bag is on screen the list stays as it was when the screen appeared")
    func theListDoesNotMoveWhileItIsRead() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 5)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        let onArrival = viewModel.changes.map(\.says)

        shop.catalog = [.fixture(id: 1, price: 14.99), .fixture(id: 2, price: 6)]
        viewModel.didChangeQuantity(productId: pid(2), quantity: 2, in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.changes.map(\.says) == onArrival)
        #expect(viewModel.changes.map(\.id) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(viewModel.total == usd(26.99))
    }

    @Test("A change stays listed after the shopper takes its line out")
    func aChangeOutlivesItsLine() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didSwipeToDelete(productId: pid(1), in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.isEmpty)
        #expect(viewModel.changes.first?.product?.title == "Product 1")
    }

    @Test("Leaving keeps the bag as it was just seen")
    func leavingKeepsTheBagAsSeen() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 5, price: 9.99), bagItem(2, price: 5), bagItem(3, price: 1)],
            catalog: [
                .fixture(id: 1, price: 12.99, availability: .inStock(remaining: 2)),
                .fixture(id: 2, availability: .outOfStock)
            ]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        let seen = viewModel.bag

        viewModel.didDisappear()

        #expect(shop.currentBag == seen)
        #expect(shop.currentBag.items.map(\.id) == [pid(1)])
        #expect(shop.currentBag.total == usd(25.98))
    }

    @Test("A change that has been seen is gone the next time the bag is opened")
    func aChangeIsShownOnce() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        #expect(viewModel.hasChanges)

        viewModel.didDisappear()
        #expect(viewModel.hasChanges == false)

        await viewModel.onAppear()

        #expect(viewModel.hasChanges == false)
        #expect(viewModel.total == usd(12.99))
    }

    @Test("Something else that changes after a visit is told on the next one, from the price last seen")
    func theNextChangeStartsFromWhatWasSeen() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()
        viewModel.didDisappear()

        shop.catalog = [.fixture(id: 1, price: 14.99)]
        await viewModel.onAppear()

        #expect(viewModel.changes.map(\.id) == [.priceWentUp(productId: pid(1), from: usd(12.99), to: usd(14.99))])
    }

    @Test("Opening the bag does not itself count as a change, or the screen would ask forever")
    func lookingDoesNotLoop() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()
        viewModel.didDisappear()
        await viewModel.inFlight?.value

        #expect(shop.lookups.count == 1)
    }

    // MARK: - Changing a line that is not what was kept

    @Test("A stepper changes the line as it is drawn, so it is kept at the price shown")
    func stepperWorksOnTheTruthfulLine() async {
        let shop = makeShop(catalog: [.fixture(id: 1, price: 12.99)])
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.rows.map(\.quantity) == [3])
        #expect(viewModel.total == usd(38.97))
        #expect(shop.currentBag.total == usd(38.97))
    }

    @Test("Asking for more than the shop has leaves the line at what is left")
    func stepperCannotPassWhatIsLeft() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 2, price: 10)],
            catalog: [.fixture(id: 1, price: 10, availability: .inStock(remaining: 2))]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.rows.map(\.quantity) == [2])
        #expect(viewModel.total == usd(20))
    }

    @Test("Swiping away a line that was repriced takes it out of the kept bag")
    func swipeWorksOnTheTruthfulLine() async {
        let shop = makeShop(
            items: [bagItem(1, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, price: 5)]
        )
        let viewModel = makeViewModel(shop: shop)
        await viewModel.onAppear()

        viewModel.didSwipeToDelete(productId: pid(1), in: inTheBag)
        await viewModel.inFlight?.value

        #expect(viewModel.rows.map(\.id) == [pid(2)])
        #expect(shop.currentBag.items.map(\.id) == [pid(2)])
    }

    // MARK: - What the checkout is handed

    @Test("The bag handed to the checkout is the one on screen: today's price, and nothing sold out")
    func theCheckoutIsHandedWhatIsShown() async {
        let shop = makeShop(
            items: [bagItem(1, quantity: 2, price: 9.99), bagItem(2, price: 5)],
            catalog: [.fixture(id: 1, price: 12.99), .fixture(id: 2, availability: .outOfStock)]
        )
        let viewModel = makeViewModel(shop: shop)

        await viewModel.onAppear()

        #expect(viewModel.bag.items.map(\.productId) == [pid(1)])
        #expect(viewModel.bag.items.map(\.lastKnownPrice) == [usd(12.99)])
        #expect(viewModel.bag.total == viewModel.total)
        #expect(Set(viewModel.products.keys) == [pid(1), pid(2)])
    }
}

/// Where the bag's own buttons are drawn. A test about what a tap does to the bag has no reason to
/// say more than that.
private let inTheBag = TrackingContext.screen("bag")
