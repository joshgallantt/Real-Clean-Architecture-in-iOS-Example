import BagTestSupport
import Foundation
import MoneyTestSupport
import ProductTestSupport
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
/// out and what was looked at, each line at the price the shopper agreed to. Where each thing
/// happened is the context its view handed over.
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

    private func makeViewModel(_ items: [BagItem], notices: Notices, shopKnows products: [Product]) -> BagScreenViewModel {
        let shop = SpyBringBagUpToDateUseCase()
        shop.products = products
        return BagScreenViewModel(
            navigation: SpyBagNavigation(),
            observeBag: StubObserveBagUseCase(Bag(items: items)),
            observeNotices: StubObserveNoticesUseCase(notices),
            setBagItemQuantity: SpySetBagItemQuantityUseCase(),
            bringBagUpToDate: shop,
            acknowledgeNotices: SpyAcknowledgeNoticesUseCase(),
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
        let lipstick = Product.fixture(id: 1, price: 12)
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], notices: Notices(), shopKnows: [lipstick])

        await appear(viewModel)

        #expect(screens.events == [.screenViewed(bag)])
        #expect(reported.events == [event(.cartViewed, about: [item(lipstick, price: 9.99, quantity: 2)], in: onTheScreen)])
    }

    @Test("The bag is viewed once a visit, however often the shop is asked again")
    func oncePerVisit() async {
        let viewModel = makeViewModel([bagItem(1, price: 9.99)], notices: Notices(), shopKnows: [.fixture(id: 1)])
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
        let viewModel = makeViewModel(lines, notices: Notices(), shopKnows: [.fixture(id: 1), .fixture(id: 2)])

        await appear(viewModel)

        #expect(reported.events == [
            event(.cartViewed, about: [item(.fixture(id: 2), price: 2, quantity: 3), item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)
        ])
    }

    @Test("A bag viewed leaves out a line the shop has not named yet")
    func bagViewedWithoutAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], notices: Notices(), shopKnows: [.fixture(id: 1)])

        await appear(viewModel)

        #expect(reported.events == [event(.cartViewed, about: [item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)])
    }

    @Test("An empty bag is not a bag viewed")
    func emptyBag() async {
        let viewModel = makeViewModel([], notices: Notices(), shopKnows: [])

        await appear(viewModel)

        #expect(reported.events.isEmpty)
    }

    @Test("A bag the shop has named nothing in is not a bag viewed either")
    func nothingNamed() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], notices: Notices(), shopKnows: [])

        await appear(viewModel)

        #expect(reported.events.isEmpty)
    }

    @Test("A line coming into view is seen where its view says it is, once the shop has named it")
    func lineSeen() async throws {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], notices: Notices(), shopKnows: [.fixture(id: 1), .fixture(id: 2)])
        await appear(viewModel)

        let second = try #require(viewModel.rows.first { $0.id == pid(2) })

        viewModel.didSee(second, in: line(1))

        #expect(views.events == [.viewed("bag_line", about: item(.fixture(id: 2), price: 2, quantity: 1), in: line(1))])
    }

    @Test("A line the shop has not named yet is not seen yet")
    func unnamedLineNotSeen() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], notices: Notices(), shopKnows: [])
        await appear(viewModel)

        viewModel.didSee(viewModel.rows[0], in: line(0))

        #expect(views.events.isEmpty)
    }

    // MARK: - Changing how many

    @Test("Turning a line up or down is a tap for how far it moved, and that many added or removed")
    func stepper() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 3, price: 5)], notices: Notices(), shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 4, in: line(0))
        viewModel.didChangeQuantity(productId: pid(1), quantity: 1, in: line(0))

        #expect(taps.events == [
            .tapped("quantity_up", about: item(.fixture(id: 1), price: 5, quantity: 1), in: line(0)),
            .tapped("quantity_down", about: item(.fixture(id: 1), price: 5, quantity: 2), in: line(0))
        ])
        #expect(changes == [
            event(.productAdded, about: [item(.fixture(id: 1), price: 5, quantity: 1)], in: line(0)),
            event(.productRemoved, about: [item(.fixture(id: 1), price: 5, quantity: 2)], in: line(0))
        ])
    }

    @Test("Turning a line of two up to five is three added, at the price the line went in at and not today's")
    func quantityUp() async {
        let lipstick = Product.fixture(id: 1, price: 12)
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], notices: Notices(), shopKnows: [lipstick])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 5, in: line(0))

        #expect(changes == [event(.productAdded, about: [item(lipstick, price: 9.99, quantity: 3)], in: line(0))])
    }

    @Test("Turning a line of five down to three is two removed, not five")
    func quantityDown() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 5, price: 9.99)], notices: Notices(), shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: line(0))

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2)], in: line(0))])
    }

    @Test("Setting a line below none removes what it had; setting it to what it holds is nothing")
    func floorAndNoChange() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 9.99)], notices: Notices(), shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: -3, in: line(0))
        viewModel.didChangeQuantity(productId: pid(1), quantity: 2, in: line(0))

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2)], in: line(0))])
    }

    @Test("Turning up a line the shop has not named yet is only the tap")
    func stepperOnAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, quantity: 2, price: 5)], notices: Notices(), shopKnows: [])
        await appear(viewModel)

        viewModel.didChangeQuantity(productId: pid(1), quantity: 3, in: line(0))

        #expect(taps.events == [.tapped("quantity_up", in: line(0))])
        #expect(reported.events.isEmpty)
    }

    // MARK: - Taking lines out

    @Test("Swiping a line away removes all of it, and says it was a swipe on that line")
    func swipe() async {
        let viewModel = makeViewModel([bagItem(7, quantity: 2, price: 3)], notices: Notices(), shopKnows: [.fixture(id: 7)])
        await appear(viewModel)

        viewModel.didSwipeToDelete(productId: pid(7), in: line(0))

        #expect(taps.events == [.tapped("remove", about: item(.fixture(id: 7), price: 3, quantity: 2), in: line(0))])
        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 7), price: 3, quantity: 2)], in: line(0))])
    }

    @Test("Remove on a line whose price went up removes all of it, in that notice's own list")
    func removeChanged() async {
        let notices = Notices([.priceWentUp(productId: pid(7), from: usd(3), to: usd(4))])
        let viewModel = makeViewModel([bagItem(7, quantity: 2, price: 4)], notices: notices, shopKnows: [.fixture(id: 7)])
        await appear(viewModel)
        let priceWentUp = TrackingContext.list(bag, TrackingContext.List(id: "bag_notices_price_went_up", name: "Price Went Up"), index: 0)

        viewModel.didRemoveChangedItem(productId: pid(7), in: priceWentUp)

        #expect(taps.events == [.tapped("remove_from_bag", about: item(.fixture(id: 7), price: 4, quantity: 2), in: priceWentUp)])
        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 7), price: 4, quantity: 2)], in: priceWentUp)])
    }

    @Test("Removing everything is one tap on the screen, and one removal of every line, each whole, as the bag keeps them")
    func removeAll() async {
        /// The bag keeps its newest line first, so each line says when it went in.
        let lines = [
            bagItem(1, quantity: 2, price: 9.99, addedAt: Date(timeIntervalSince1970: 2)),
            bagItem(2, price: 5, addedAt: Date(timeIntervalSince1970: 1))
        ]
        let viewModel = makeViewModel(lines, notices: Notices(), shopKnows: [.fixture(id: 1), .fixture(id: 2)])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(taps.events == [.tapped("remove_all", in: onTheScreen)])
        #expect(changes == [
            event(.productRemoved, about: [item(.fixture(id: 1), price: 9.99, quantity: 2), item(.fixture(id: 2), price: 5, quantity: 1)], in: onTheScreen)
        ])
    }

    @Test("Lines that leave are reported without one the shop has not named yet")
    func removeAllWithoutAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1), bagItem(2, price: 2)], notices: Notices(), shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(changes == [event(.productRemoved, about: [item(.fixture(id: 1), price: 1, quantity: 1)], in: onTheScreen)])
    }

    @Test("Removing everything from an empty bag is the tap, and not a removal")
    func nothingToRemove() async {
        let viewModel = makeViewModel([], notices: Notices(), shopKnows: [])
        await appear(viewModel)

        viewModel.didRemoveEverything(in: onTheScreen)

        #expect(taps.events == [.tapped("remove_all", in: onTheScreen)])
        #expect(reported.events.isEmpty)
    }

    @Test("Swiping away a line the shop has not named yet is only the tap")
    func swipeOnAnUnnamedLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], notices: Notices(), shopKnows: [])
        await appear(viewModel)

        viewModel.didSwipeToDelete(productId: pid(1), in: line(0))

        #expect(taps.events == [.tapped("remove", in: line(0))])
        #expect(reported.events.isEmpty)
    }

    // MARK: - Opening and accepting

    @Test("Tapping a line opens it, reported as a tap on that line")
    func tapLine() async {
        let viewModel = makeViewModel([bagItem(1, price: 1)], notices: Notices(), shopKnows: [.fixture(id: 1)])
        await appear(viewModel)

        viewModel.didTapRow(viewModel.rows[0], in: line(0))

        #expect(taps.events == [.tapped("bag_line", about: item(.fixture(id: 1), price: 1, quantity: 1), in: line(0))])
    }

    @Test("Tapping a notice line is reported in that notice's own list")
    func tapNotice() async {
        let notices = Notices([.outOfStock(productId: pid(4))])
        let viewModel = makeViewModel([bagItem(1, price: 1)], notices: notices, shopKnows: [.fixture(id: 1), .fixture(id: 4)])
        await appear(viewModel)
        let soldOut = TrackingContext.list(bag, TrackingContext.List(id: "bag_notices_out_of_stock", name: "Sold Out"), index: 0)

        viewModel.didTapRow(viewModel.notices(in: .outOfStock)[0], in: soldOut)

        #expect(taps.events == [.tapped("notice_line", about: TrackedProduct.item(.fixture(id: 4)), in: soldOut)])
    }

    @Test("Okay on a section is a tap named for that section")
    func acceptAll() async {
        let viewModel = makeViewModel([], notices: Notices([.outOfStock(productId: pid(4))]), shopKnows: [])
        await appear(viewModel)

        viewModel.didAcceptAll(.outOfStock, in: onTheScreen)

        #expect(taps.events == [.tapped("accept_all_out_of_stock", in: onTheScreen)])
    }
}
