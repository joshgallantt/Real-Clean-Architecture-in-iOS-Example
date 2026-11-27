import BagTestSupport
import Foundation
import MoneyTestSupport
import ProductTestSupport
import SettingsTestSupport
import Testing
import Bag
import Money
import Product
import Tracking
import TrackingUI
import TrackingTestSupport
@testable import BagUI
@testable import BagUITestSupport

@MainActor
@Suite("What the bag tells the shop")
/// The screen says what was seen and touched, and what that did to the bag: what went in, what came
/// out and what was looked at, each line at the price it was showing. Where each thing happened is
/// the context its view handed over.
struct TrackingTheBagTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let reported = SpyTrackEventUseCase()
    private let bag = "bag"
    private let onTheScreen = TrackingContext.screen("bag")

    private func line(_ index: Int) -> TrackingContext {
        .list(bag, TrackingContext.List(id: "bag", name: "Bag"), index: index)
    }

    private var changedList: TrackingContext.List {
        TrackingContext.List(id: "bag_changes", name: "Changes Since You Last Viewed")
    }

    /// A screen over a kept bag and a shop that describes exactly these products. A line the shop
    /// does not describe was not asked about, so it stays on screen without a name.
    private func makeViewModel(_ items: [BagItem], shopKnows products: [Product]) -> BagScreenViewModel {
        let kept = Bag(items: items)
        return BagScreenViewModel(
            navigation: SpyBagNavigation(),
            observeBag: StubObserveBagUseCase(kept),
            setBagItem: SpySetBagItemUseCase(),
            checkBag: SpyCheckBagUseCase(answer: kept.checked(against: products, asked: Set(products.map(\.id)))),
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
    }

    private func appear(_ viewModel: BagScreenViewModel) async {
        viewModel.didAppear(in: onTheScreen)
        await viewModel.onAppear()
    }

    private func item(_ product: Product, price: Decimal, quantity: Int) -> TrackedItem {
        TrackedProduct.item(product, price: usd(price), quantity: quantity)
    }

    private func event(_ name: EventName, about items: [TrackedItem], in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(name: name, context: context, items: items, properties: [:])
    }

    /// What was reported about the bag changing. Coming into view reports the bag viewed first, and
    /// a test about a change is not about that.
    private var changes: [TrackingEvent] {
        reported.events.filter { $0.name != .cartViewed }
    }

    // MARK: - Looking at the bag

    @Test("Coming into view reports the bag screen, then the bag viewed once the shop has named what is in it")
    func screenThenBagViewed() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], shopKnows: [.fixture(id: 1)])

        await appear(viewModel)

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen(bag), items: [], properties: [:])])
        #expect(reported.events == [event(.cartViewed, about: [item(.fixture(id: 1), price: 9.99, quantity: 2)], in: onTheScreen)])
    }

    @Test("A bag viewed is the bag as it is drawn: today's price, what the shop has left, and nothing sold out")
    func bagViewedIsTheTruthfulBag() async {
        let lines = [
            bagItem(1, quantity: 5, price: 9.99, addedAt: Date(timeIntervalSince1970: 2)),
            bagItem(2, price: 5, addedAt: Date(timeIntervalSince1970: 1))
        ]
        let lipstick = Product.fixture(id: 1, price: 12, availability: .inStock(remaining: 2))
        let viewModel = makeViewModel(lines, shopKnows: [lipstick, .fixture(id: 2, availability: .outOfStock)])

        await appear(viewModel)

        #expect(reported.events == [event(.cartViewed, about: [item(lipstick, price: 12, quantity: 2)], in: onTheScreen)])
    }

    @Test("A bag the shop has sold out of entirely is not a bag viewed")
    func everythingSoldOut() async {
        let viewModel = makeViewModel([bagItem(1, price: 9.99)], shopKnows: [.fixture(id: 1, availability: .outOfStock)])

        await appear(viewModel)

        #expect(reported.events.isEmpty)
    }

    @Test("The bag is viewed once a visit, however often the shop is asked again")
    func oncePerVisit() async {
        let viewModel = makeViewModel([bagItem(1, price: 9.99)], shopKnows: [.fixture(id: 1)])
        let viewed = event(.cartViewed, about: [item(.fixture(id: 1), price: 9.99, quantity: 1)], in: onTheScreen)

        await appear(viewModel)
        await viewModel.onAppear()
        #expect(reported.events == [viewed])

        await appear(viewModel)
        #expect(reported.events == [viewed, viewed])
    }

    @Test("A bag viewed names its lines as the bag keeps them, the newest first")
    func bagViewedInTheBagsOrder() async {
        let lines = [
            bagItem(1, price: 1, addedAt: Date(timeIntervalSince1970: 1)),
            bagItem(2, quantity: 3, price: 2, addedAt: Date(timeIntervalSince1970: 2))
        ]
        let viewModel = makeViewModel(lines, shopKnows: [.fixture(id: 1, price: 1), .fixture(id: 2, price: 2)])

        await appear(viewModel)

        #expect(reported.events == [
            event(.cartViewed, about: [item(.fixture(id: 2), price: 2, quantity: 3), item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)
        ])
    }

    @Test("A bag viewed leaves out a line the shop has not named yet")
    func bagViewedWithoutAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], shopKnows: [.fixture(id: 1, price: 1)])

        await appear(viewModel)

        #expect(reported.events == [event(.cartViewed, about: [item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)])
    }

    @Test("An empty bag is not a bag viewed")
    func emptyBag() async {
        let viewModel = makeViewModel([], shopKnows: [])

        await appear(viewModel)

        #expect(reported.events.isEmpty)
    }

    @Test("A bag the shop has named nothing in is not a bag viewed either")
    func nothingNamed() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], shopKnows: [])

        await appear(viewModel)

        #expect(reported.events.isEmpty)
    }

    @Test("A line coming into view is seen where its view says it is, once the shop has named it")
    func lineSeen() async throws {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], shopKnows: [.fixture(id: 1, price: 1), .fixture(id: 2, price: 2)])
        await appear(viewModel)

        let second = try #require(viewModel.rows.first { $0.id == pid(2) })

        viewModel.didSee(second, in: line(1))

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: line(1), items: [item(.fixture(id: 2), price: 2, quantity: 1)], properties: ["element": "bag_line"])])
    }

    @Test("A line the shop has not named yet is not seen yet")
    func unnamedLineNotSeen() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], shopKnows: [])
        await appear(viewModel)

        viewModel.didSee(viewModel.rows[0], in: line(0))

        #expect(views.events.isEmpty)
    }

    // MARK: - Changing how many

    @Test("Turning a line up or down is a tap for how far it moved, and that many added or removed")
    func stepper() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 3, price: 5)], shopKnows: [.fixture(id: 1, price: 5)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 4, in: line(0))
        viewModel.didChangeQuantity(productId: pid(1), quantity: 1, in: line(0))

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: line(0), items: [item(.fixture(id: 1), price: 5, quantity: 1)], properties: ["element": "quantity_up"]),
            TrackingEvent(name: .elementSelected, context: line(0), items: [item(.fixture(id: 1), price: 5, quantity: 2)], properties: ["element": "quantity_down"])
        ])
        #expect(changes == [
            event(.productAdded, about: [item(.fixture(id: 1), price: 5, quantity: 1)], in: line(0)),
            event(.productRemoved, about: [item(.fixture(id: 1), price: 5, quantity: 2)], in: line(0))
        ])
    }

    @Test("Turning a line of two up to five is three added, at the price the line is showing and not the one it was kept at")
    func quantityUp() async {
        let lipstick = Product.fixture(id: 1, price: 12)
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], shopKnows: [lipstick])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 5, in: line(0))

        #expect(changes == [event(.productAdded, about: [item(lipstick, price: 12, quantity: 3)], in: line(0))])
    }

    @Test("Turning a line up past what the shop has left adds only what there is")
    func quantityUpPastWhatIsLeft() async {
        let lipstick = Product.fixture(id: 1, price: 12, availability: .inStock(remaining: 3))
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 12)], shopKnows: [lipstick])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 5, in: line(0))

        #expect(changes == [event(.productAdded, about: [item(lipstick, price: 12, quantity: 1)], in: line(0))])
    }

    @Test("Turning up a line that already holds all the shop has is nothing added, and no tap that moved anything")
    func quantityUpWithNoneLeft() async {
        let lipstick = Product.fixture(id: 1, price: 12, availability: .inStock(remaining: 2))
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 12)], shopKnows: [lipstick])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: line(0))

        #expect(changes.isEmpty)
        #expect(taps.events.isEmpty)
    }

    @Test("Turning a line of five down to three is two removed, not five")
    func quantityDown() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 5, price: 9.99)], shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: line(0))

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2)], in: line(0))])
    }

    @Test("Setting a line below none removes what it had; setting it to what it holds is nothing")
    func floorAndNoChange() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: -3, in: line(0))
        viewModel.didChangeQuantity(productId: pid(1), quantity: 2, in: line(0))

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2)], in: line(0))])
    }

    @Test("Turning up a line the shop has not named yet is only the tap")
    func stepperOnAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 5)], shopKnows: [])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: line(0))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: line(0), items: [], properties: ["element": "quantity_up"])])
        #expect(reported.events.isEmpty)
    }

    // MARK: - Taking lines out

    @Test("Swiping a line away removes all of it, and says it was a swipe on that line")
    func swipe() async {
        let viewModel = makeViewModel([bagItem(7, quantity: 2, price: 3)], shopKnows: [.fixture(id: 7, price: 3)])
        await appear(viewModel)

        viewModel.didSwipeToDelete(productId: pid(7), in: line(0))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: line(0), items: [item(.fixture(id: 7), price: 3, quantity: 2)], properties: ["element": "remove"])])
        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 7), price: 3, quantity: 2)], in: line(0))])
    }

    @Test("Removing everything is one tap on the screen, and one removal of every line, each whole, as the bag keeps them")
    func removeAll() async {
        /// The bag keeps its newest line first, so each line says when it went in.
        let lines = [
            bagItem(1, quantity: 2, price: 9.99, addedAt: Date(timeIntervalSince1970: 2)),
            bagItem(2, price: 5, addedAt: Date(timeIntervalSince1970: 1))
        ]
        let viewModel = makeViewModel(lines, shopKnows: [.fixture(id: 1), .fixture(id: 2, price: 5)])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onTheScreen, items: [], properties: ["element": "remove_all"])])
        #expect(changes == [
            event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2), item(.fixture(id: 2), price: 5, quantity: 1)], in: onTheScreen)
        ])
    }

    @Test("Lines that leave are reported without one the shop has not named yet")
    func removeAllWithoutAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], shopKnows: [.fixture(id: 1, price: 1)])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)])
    }

    @Test("Removing everything from an empty bag is the tap, and not a removal")
    func nothingToRemove() async {
        let viewModel = makeViewModel([], shopKnows: [])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onTheScreen, items: [], properties: ["element": "remove_all"])])
        #expect(reported.events.isEmpty)
    }

    @Test("Swiping away a line the shop has not named yet is only the tap")
    func swipeOnAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], shopKnows: [])
        await appear(viewModel)

        viewModel.didSwipeToDelete(productId: pid(1), in: line(0))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: line(0), items: [], properties: ["element": "remove"])])
        #expect(reported.events.isEmpty)
    }

    // MARK: - Opening

    @Test("Tapping a line opens it, reported as a tap on that line")
    func tapLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], shopKnows: [.fixture(id: 1, price: 1)])
        await appear(viewModel)

        viewModel.didTapRow(viewModel.rows[0], in: line(0))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: line(0), items: [item(.fixture(id: 1), price: 1, quantity: 1)], properties: ["element": "bag_line"])])
    }

    // MARK: - What changed since the bag was last viewed

    @Test("Something that changed is seen in the changes list, as the product it is about")
    func changeSeen() async throws {
        let dearer = Product.fixture(id: 4, price: 12)
        let viewModel = makeViewModel([bagItem(4, price: 9.99)], shopKnows: [dearer])
        await appear(viewModel)
        let first = TrackingContext.list(bag, changedList, index: 0)

        viewModel.didSee(try #require(viewModel.changes.first), in: first)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: first, items: [TrackedProduct.item(dearer)], properties: ["element": "bag_change_line"])])
    }

    @Test("Tapping something that changed is reported in the changes list, whatever kind of change it was")
    func changeTapped() async throws {
        let soldOut = Product.fixture(id: 4, availability: .outOfStock)
        let viewModel = makeViewModel([bagItem(1, price: 9.99), bagItem(4, price: 9.99)], shopKnows: [.fixture(id: 1), soldOut])
        await appear(viewModel)
        let first = TrackingContext.list(bag, changedList, index: 0)

        viewModel.didTapRow(try #require(viewModel.changes.first), in: first)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: first, items: [TrackedProduct.item(soldOut)], properties: ["element": "bag_change_line"])])
    }

    @Test("Leaving the bag reports nothing: keeping it as it was seen is not the shopper taking things out")
    func leavingReportsNothing() async {
        let viewModel = makeViewModel(
            [bagItem(1, quantity: 5, price: 9.99), bagItem(2, price: 5)],
            shopKnows: [.fixture(id: 1, price: 12, availability: .inStock(remaining: 2)), .fixture(id: 2, availability: .outOfStock)]
        )
        await appear(viewModel)

        viewModel.didDisappear()

        #expect(taps.events.isEmpty)
        #expect(changes.isEmpty)
    }
}
