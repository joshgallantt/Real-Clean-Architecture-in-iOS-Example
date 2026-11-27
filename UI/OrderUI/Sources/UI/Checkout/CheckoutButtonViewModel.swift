import Combine
import Foundation
import Bag
import Money
import Order
import Product
import AuthUI
import SnackbarUI
import Tracking
import TrackingUI

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 13 — Component Cohesion: this lives in `OrderUI` rather than `BagUI` because it
/// changes when ordering changes, not when the bag does. `BagUI` is handed a finished button and
/// never learns there is an order domain, the same way it is handed a stock alert bell.
public final class CheckoutButtonViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var isPlacing = false
    private(set) var bag = Bag()

    private let observeBag: ObserveBagUseCase
    private let placeOrder: PlaceOrderUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let confirm: (Order) -> Void
    private let products: @MainActor () -> [ProductID: Product]
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(
        observeBag: ObserveBagUseCase,
        placeOrder: PlaceOrderUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        confirm: @escaping (Order) -> Void,
        products: @escaping @MainActor () -> [ProductID: Product],
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.observeBag = observeBag
        self.placeOrder = placeOrder
        self.setBagItemQuantity = setBagItemQuantity
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.confirm = confirm
        self.products = products
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// Subscribing happens here rather than in `init`, because `@State` builds its
    /// initial value on every view initialisation and a subscription is a side
    /// effect Apple's guidance says to keep out of that.
    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeBag()
            .sink { [weak self] bag in
                self?.bag = bag
            }
            .store(in: &cancellables)
    }

    var isEmpty: Bool { bag.isEmpty }

    var totalLabel: String { bag.total?.formatted() ?? "" }

    /// The names on a checkout are the bag screen's: it is handed the products the bag is drawing,
    /// so the report says what was bought, not only which ids. Read before the bag is emptied,
    /// since an emptied bag stops drawing them.
    ///
    /// The guard against a second tap lives here rather than in `checkOut`, because `checkOut` calls
    /// itself after a shopper signs in. A guard inside it would treat that resumed order as the
    /// double tap it exists to stop, and the shopper would sign in to nothing happening.
    func didTap(in context: TrackingContext) {
        guard !isPlacing else { return }
        trackElementInteraction(OrderTrackingPlan.checkOut, in: context)
        report(.checkoutStarted, about: whatTheyAreBuying, properties: [:], in: context)
        inFlight = Task {
            isPlacing = true
            defer { isPlacing = false }
            await checkOut(in: context)
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring, converting what a bag holds into what an order is made of. The price a shopper is
    /// charged is the one their bag was showing them, which `BringBagUpToDateUseCase` has already
    /// brought level with the shop.
    private var whatTheyAreBuying: [OrderLine] {
        bag.items.map {
            OrderLine(productId: $0.productId, quantity: $0.quantity, pricePaid: $0.lastKnownPrice)
        }
    }

    /// A step through ordering, about the lines it concerns at the price being paid — never
    /// today's. A line the bag screen cannot name is left out, and a step with nothing nameable in
    /// it is not reported.
    private func report(_ name: EventName, about lines: [OrderLine], properties: [PropertyKey: String], in context: TrackingContext) {
        let named = products()
        let items = lines.compactMap { line in
            named[line.productId].map { TrackedProduct.item($0, price: line.pricePaid, quantity: line.quantity) }
        }
        guard !items.isEmpty else { return }
        trackEvent(TrackingEvent(name: name, context: context, items: items, properties: properties))
    }

    private func show(_ snackbar: Snackbar, in context: TrackingContext) {
        trackElementView(snackbar.trackingName, in: context)
        snackbarPresenter.show(snackbar)
    }

    private func checkOut(in context: TrackingContext) async {
        switch await placeOrder(whatTheyAreBuying) {
        case .success(let order):
            /// The order's own id goes with it, so a purchase reported twice is one purchase in the report.
            report(.orderCompleted, about: order.lines, properties: [.orderId: order.id.rawValue], in: context)
            emptyTheBag()
            confirm(order)

        case .failure(.unauthenticated):
            let signedIn = await authPresenter.show(AuthenticationPrompt(
                title: "Almost Yours",
                message: "Sign in so we know where to send it.",
                icon: "bag.fill"
            ))
            /// The sheet covered the screen; closing it does not make the screen appear again.
            trackScreenView(context.screen)
            guard signedIn else { return }
            await checkOut(in: context)

        case .failure(.paymentDeclined):
            show(Snackbar(
                title: "Payment Declined",
                message: "That card didn't go through. Your bag's still here.",
                icon: "creditcard.trianglebadge.exclamationmark"
            ), in: context)

        case .failure(.unavailable):
            show(Snackbar(
                title: "That Didn't Go Through",
                message: "Our end, not yours. Your bag's still here.",
                icon: "exclamationmark.triangle",
                action: .retry { self.didTap(in: context) }
            ), in: context)

        case .failure(.nothingToOrder):
            show(Snackbar(
                title: "Nothing in Your Bag",
                message: "Add something first.",
                icon: "bag"
            ), in: context)
        }
    }

    /// Only once the order exists. A bag emptied before the payment went through would leave a
    /// shopper with neither, which is the worst of the three outcomes and the easiest to cause.
    ///
    /// Every line goes the way a single swipe sends one, so there is no second path through the
    /// domain to keep in step with the first.
    private func emptyTheBag() {
        for item in bag.items {
            setBagItemQuantity(productId: item.productId, to: 0)
        }
    }
}
