import Combine
import Foundation
import Bag
import Money
import Product
import Settings
import Tracking
import TrackingUI

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
///
/// Two bags are in play and only one is drawn. The bag that is kept is the one the shopper last
/// saw; the bag on screen is that one held against what the shop says now. The difference between
/// them is what the changes section lists, and leaving the screen keeps the second as the first.
public final class BagScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var rows: [BagRow] = []

    /// What changed since the shopper last viewed their bag, as it stood when the screen came into
    /// view. It does not move while they are looking: a list that rewrote itself under a shopper
    /// reading it would be telling them something different each time they glanced at it.
    private(set) var changes: [BagChangeRow] = []

    /// The bag as it is drawn: today's prices, no more of anything than the shop has, and no line
    /// the shop cannot supply. Public because the checkout button below it, built in another
    /// package's container, buys exactly this — what a shopper sees is what they pay.
    public private(set) var bag = Bag()

    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let setBagItem: SetBagItemUseCase
    private let checkBag: CheckBagUseCase
    private let observeSetting: ObserveSettingUseCase

    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    /// Where the last visit to this screen was, as its view said — so the bag viewed once the shop
    /// answers is reported on the screen that asked.
    @ObservationIgnored private var visit = TrackingContext.screen(BagTrackingPlan.screen)

    /// Whether this visit has reported the bag as viewed yet. A visit starts when the screen comes
    /// into view; the bag counts as viewed once the shop has said what is in it.
    @ObservationIgnored private var hasReportedBagViewed = false

    private var cancellables = Set<AnyCancellable>()

    /// The bag as it is kept, which is the bag as the shopper last saw it.
    private var kept = Bag()

    /// The last thing the shop said. It is held against the kept bag again every time that bag
    /// changes, so a tap on a stepper redraws truthfully at once rather than after a round trip.
    private var shopSaid = Bag().checked(against: [], asked: [])

    /// What had changed when this visit began — every change, whether or not the section that
    /// lists them is switched on.
    private var changesOnArrival: [BagChange] = []
    private var showsChanges = true
    private var catalog: [ProductID: Product] = [:]

    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: always from the bag, never the catalog, so the total
    /// is the sum of the lines above it.
    var total: Money? { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    /// Whether there is anything to tell the shopper. A bag the shop has emptied is not an empty
    /// screen — what changed is the reason it emptied.
    var hasChanges: Bool { !changes.isEmpty }

    var itemCountSummary: String {
        bag.itemCount == 1 ? "1 item" : "\(bag.itemCount) items"
    }

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        setBagItem: SetBagItemUseCase,
        checkBag: CheckBagUseCase,
        observeSetting: ObserveSettingUseCase,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.setBagItem = setBagItem
        self.checkBag = checkBag
        self.observeSetting = observeSetting
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// The products this screen has been told about, for the checkout button below it to name what
    /// is being bought. Public because the button is built in another package's container.
    public var products: [ProductID: Product] { catalog }

    // MARK: - Tracking

    func didAppear(in context: TrackingContext) {
        visit = context
        hasReportedBagViewed = false
        trackScreenView(context.screen)
    }

    /// A line seen, where its view says it is. Not until the shop has said what it is: a placeholder
    /// row has no name to report it by.
    func didSee(_ row: BagRow, in context: TrackingContext) {
        guard let product = row.product, let line = line(row.id) else { return }
        trackElementView(BagTrackingPlan.line, about: item(line, product: product, quantity: line.quantity), in: context)
    }

    func didSee(_ row: BagChangeRow, in context: TrackingContext) {
        guard let product = row.product else { return }
        trackElementView(BagTrackingPlan.changeLine, about: TrackedProduct.item(product), in: context)
    }

    /// Once per visit, and only once the shop has answered — so a bag viewed carries the names and
    /// the prices the shopper is looking at, not a list of ids.
    private func reportBagViewedIfDue() {
        guard !hasReportedBagViewed, !bag.isEmpty else { return }
        hasReportedBagViewed = true
        report(.cartViewed, about: bag.items, in: visit)
    }

    /// A tap on something on a line, about that line where the shop has said what it is.
    private func tapped(_ element: String, on line: BagItem, quantity: Int, in context: TrackingContext) {
        guard let product = catalog[line.productId] else {
            trackElementInteraction(element, in: context)
            return
        }
        trackElementInteraction(element, about: item(line, product: product, quantity: quantity), in: context)
    }

    /// A line set to a new quantity. Up is something added and down is something removed, by however
    /// much it moved — a shopper taking two off a line of five has removed two, not five.
    ///
    /// The bag's own floor applies — nothing goes below none — so setting a line to -3 removes what
    /// the line had, and setting it to what it already holds is no step at all. A line the shop has
    /// not answered about has no name to be reported by.
    private func reportQuantityChange(of line: BagItem, to quantity: Int, in context: TrackingContext) {
        let change = max(quantity, 0) - line.quantity
        guard change != 0, let product = catalog[line.productId] else { return }

        let name: EventName = change > 0 ? .productAdded : .productRemoved
        let items = [item(line, product: product, quantity: abs(change))]
        trackEvent(TrackingEvent(name: name, context: context, items: items, properties: [:]))
    }

    /// Whole lines in one event: the ones that left the bag, or the bag as it was looked at.
    ///
    /// The bag keeps ids and a report wants names. A line the shop has not answered about has no name
    /// to report, so it is left out — and an event left with nothing in it did not happen, so it is
    /// not reported at all. A bag viewed empty is not a bag viewed.
    private func report(_ name: EventName, about lines: [BagItem], in context: TrackingContext) {
        let items = lines.compactMap { line in
            catalog[line.productId].map { item(line, product: $0, quantity: line.quantity) }
        }
        guard !items.isEmpty else { return }
        trackEvent(TrackingEvent(name: name, context: context, items: items, properties: [:]))
    }

    /// A bag line as something the shop can measure — at the price the line is showing, which is
    /// the price it would be bought at — and however many of it the event is about.
    private func item(_ line: BagItem, product: Product, quantity: Int) -> TrackedItem {
        TrackedProduct.item(product, price: line.lastKnownPrice, quantity: quantity)
    }

    /// The line as it is drawn. Steppers and swipes act on this one, so what a shopper changes is
    /// the line they are looking at and it is kept at the price they were shown.
    private func line(_ productId: ProductID) -> BagItem? {
        bag.items.first { $0.id == productId }
    }

    // MARK: - Coming and going

    /// `async` so the screen can await it from `.task`, which ties the ask to how
    /// long the bag is on screen and cancels it on the way out. A tap has no async
    /// context and goes through `startAskingTheShop()` instead.
    ///
    /// What changed is taken from this answer and no later one: it is what the shopper is told
    /// for the whole of the visit.
    func onAppear() async {
        if cancellables.isEmpty {
            subscribe()
        }

        let said = await checkBag()
        guard !Task.isCancelled else { return }

        changesOnArrival = said.changes
        learn(said)
    }

    /// The shopper has seen the bag as it is drawn, so that is the bag to keep — a line at a time,
    /// the way every other change to a bag is made. Whatever they were told is now old news, and
    /// the next visit will find nothing to tell unless the shop changes something else.
    func didDisappear() {
        for line in kept.lines(toBecome: bag) {
            setBagItem(line)
        }
        changesOnArrival = []
        render()
    }

    // MARK: - What the shopper does

    /// Two things to say: which way the stepper went, and what that added to or took from the bag.
    /// A line the shop has not answered about has no name to be reported by, so only the tap is.
    ///
    /// A line cannot hold more than the shop has left, so a step past that is cut to what there is
    /// — and a step that changes nothing is not reported as one, or it would say something was
    /// added that never was.
    func didChangeQuantity(productId: ProductID, quantity: Int, in context: TrackingContext) {
        if let line = line(productId) {
            let quantity = quantityTheShopCanSupply(of: line, wanting: quantity)
            if quantity != line.quantity {
                let change = quantity - line.quantity
                tapped(change > 0 ? BagTrackingPlan.quantityUp : BagTrackingPlan.quantityDown, on: line, quantity: abs(change), in: context)
                reportQuantityChange(of: line, to: quantity, in: context)
                setBagItem(line.withQuantity(quantity))
            }
        }
        startAskingTheShop()
    }

    /// What the shop has not answered about is not capped: there is nothing yet to cap it to.
    private func quantityTheShopCanSupply(of line: BagItem, wanting quantity: Int) -> Int {
        guard let product = catalog[line.productId] else { return quantity }
        return min(quantity, product.availability.remaining)
    }

    func didSwipeToDelete(productId: ProductID, in context: TrackingContext) {
        if let line = line(productId) {
            tapped(BagTrackingPlan.swipeRemove, on: line, quantity: line.quantity, in: context)
            report(.productRemoved, about: [line], in: context)
            setBagItem(line.withQuantity(0))
        }
        startAskingTheShop()
    }

    /// Any row on this screen goes to its product, a line of the bag or something that changed.
    /// Opening it is behaviour, so it lives here rather than being called straight out of the view
    /// — where nothing could reach it.
    ///
    /// The product goes to navigation, not its id — see `BagNavigation`. This screen has already
    /// been told what every row is, which is where its names and pictures come from, so it opens
    /// what it is drawing rather than asking the app layer to go and find it again. A row the shop
    /// has not answered about yet has no page to open, and drawing it as a name-less row is the
    /// same fact said in the other direction.
    ///
    /// A product can be both a line and a change — a price that went up is still in the bag — so
    /// there is one of these for each, and the view says which it was tapped in by which it calls.
    func didTapRow(_ row: BagRow, in context: TrackingContext) {
        guard let product = catalog[row.id] else { return }
        if let line = line(row.id) {
            trackElementInteraction(BagTrackingPlan.line, about: item(line, product: product, quantity: line.quantity), in: context)
        }
        navigation.openProductDetails(product: product)
    }

    func didTapRow(_ row: BagChangeRow, in context: TrackingContext) {
        guard let product = row.product else { return }
        trackElementInteraction(BagTrackingPlan.changeLine, about: TrackedProduct.item(product), in: context)
        navigation.openProductDetails(product: product)
    }

    /// The shopper empties their own bag. Every line goes the way a single swipe sends one, so
    /// there is no second path through the domain to keep in step with the first.
    func didRemoveEverything(in context: TrackingContext) {
        trackElementInteraction(BagTrackingPlan.removeAll, in: context)
        report(.productRemoved, about: bag.items, in: context)
        for item in bag.items {
            setBagItem(item.withQuantity(0))
        }
        startAskingTheShop()
    }

    // MARK: -

    private func subscribe() {
        observeBag()
            .sink { [weak self] kept in
                self?.kept = kept
                self?.render()
            }
            .store(in: &cancellables)

        observeSetting(.bagChangesSection)
            .sink { [weak self] isOn in
                self?.showsChanges = isOn
                self?.render()
            }
            .store(in: &cancellables)
    }

    /// The one place the kept bag becomes the bag on screen. Before the shop has said anything
    /// nothing was asked, so the two are the same bag and the rows do not wait for an answer.
    private func render() {
        bag = kept.checked(against: shopSaid.products, asked: shopSaid.asked).bag

        rows = bag.items.map { item in
            BagRow(item: item, product: catalog[item.id])
        }

        changes = showsChanges
            ? changesOnArrival.map { BagChangeRow(change: $0, product: catalog[$0.productId]) }
            : []
    }

    /// SwiftUI calls a button action synchronously, so a tap starts the ask and
    /// returns. The handle is what makes a fresh ask replace the one before it,
    /// and what lets a test wait for work a tap started rather than guess at it.
    ///
    /// What changed is not taken from this answer: the list is the one the visit began with.
    private func startAskingTheShop() {
        inFlight?.cancel()
        inFlight = Task { [weak self] in
            guard let self else { return }
            let said = await self.checkBag()
            guard !Task.isCancelled else { return }
            self.learn(said)
        }
    }

    /// The whole bag is asked about every time, not a page of it: what a bag is worth is a fact
    /// about all of it. The use case does the asking and hands back what it was told, so this
    /// screen gets its names and pictures out of the same reply that settled the prices.
    ///
    /// An answer to nothing teaches nothing. An empty bag asks nothing, and so does a shop that
    /// could not be reached — and a dropped connection must not put back a line the shop had
    /// already said was sold out. What was last known stands until there is a real answer.
    private func learn(_ said: CheckedBag) {
        if !said.asked.isEmpty {
            shopSaid = said
        }

        for product in said.products {
            catalog[product.id] = product
        }

        /// Every product on screen: what is in the kept bag, and what the changes are about. The
        /// two are not the same set — something sold out is listed after its line has gone.
        let onScreen = Set(kept.items.map(\.id)).union(changesOnArrival.map(\.productId))
        catalog = catalog.filter { onScreen.contains($0.key) }

        render()
        reportBagViewedIfDue()
    }
}
