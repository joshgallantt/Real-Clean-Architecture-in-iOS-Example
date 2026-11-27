import Foundation
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
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class BuyNowButtonViewModel {
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

    private let product: Product
    private let placeOrder: PlaceOrderUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let confirm: (Order) -> Void
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        product: Product,
        placeOrder: PlaceOrderUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        confirm: @escaping (Order) -> Void,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.product = product
        self.placeOrder = placeOrder
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.confirm = confirm
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    var priceLabel: String { product.price.formatted() }

    /// Tracked here, once, for the same reason: signing in part-way and carrying on is still the
    /// one tap and the one checkout. The purchase is tracked only once there is an order.
    ///
    /// The guard against a second tap lives here rather than in `buy`, because `buy` calls itself
    /// after a shopper signs in. A guard inside it would treat that resumed order as the double tap
    /// it exists to stop, and the shopper would sign in to nothing happening.
    ///
    /// `context` is wherever the button is drawn, as the view read it.
    func didTap(in context: TrackingContext) {
        guard !isPlacing else { return }
        trackElementInteraction(OrderTrackingPlan.buyNow, about: item, in: context)
        report(.checkoutStarted, about: whatTheyAreBuying, properties: [:], in: context)
        inFlight = Task {
            isPlacing = true
            defer { isPlacing = false }
            await buy(in: context)
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring turning what the catalog knows into what the order use case wants. One of this product,
    /// at the price the shopper is looking at — Buy Now never touches the bag, which is the whole
    /// difference between it and checking out.
    private var whatTheyAreBuying: [OrderLine] {
        [OrderLine(productId: product.id, quantity: 1, pricePaid: product.price)]
    }

    /// One of this product, at the price on the page — what Buy Now buys.
    private var item: TrackedItem { TrackedProduct.item(product) }

    /// A step through ordering, about the lines it concerns at the price being paid — never
    /// today's. The page can name one product, its own: a line about anything else is left out, and
    /// a step with nothing nameable in it is not reported.
    private func report(_ name: EventName, about lines: [OrderLine], properties: [PropertyKey: String], in context: TrackingContext) {
        let items = lines
            .filter { $0.productId == product.id }
            .map { TrackedProduct.item(product, price: $0.pricePaid, quantity: $0.quantity) }
        guard !items.isEmpty else { return }
        trackEvent(TrackingEvent(name: name, context: context, items: items, properties: properties))
    }

    private func show(_ snackbar: Snackbar, in context: TrackingContext) {
        trackElementView(snackbar.trackingName, about: item, in: context)
        snackbarPresenter.show(snackbar)
    }

    private func buy(in context: TrackingContext) async {
        switch await placeOrder(whatTheyAreBuying) {
        case .success(let order):
            /// The order's own id goes with it, so a purchase reported twice is one purchase in the report.
            report(.orderCompleted, about: order.lines, properties: [.orderId: order.id.rawValue], in: context)
            confirm(order)

        /// The same move the wishlist heart makes: ask at the moment it is actually needed, and
        /// carry on if they signed in. A shopper who backs out is left where they were.
        case .failure(.unauthenticated):
            let signedIn = await authPresenter.show(AuthenticationPrompt(
                title: "Almost Yours",
                message: "Sign in so we know where to send it.",
                icon: "bag.fill"
            ))
            /// The sheet covered the screen; closing it does not make the screen appear again.
            trackScreenView(context.screen)
            guard signedIn else { return }
            await buy(in: context)

        case .failure(.paymentDeclined):
            show(Snackbar(
                title: "Payment Declined",
                message: "That card didn't go through. Try another one.",
                icon: "creditcard.trianglebadge.exclamationmark"
            ), in: context)

        case .failure(.unavailable):
            show(Snackbar(
                title: "That Didn't Go Through",
                message: "Our end, not yours. Give it another go.",
                icon: "exclamationmark.triangle",
                action: .retry { self.didTap(in: context) }
            ), in: context)

        /// A product page always has exactly one thing to buy, so this cannot happen from here. It
        /// is not silently ignored, because a button that quietly does nothing is the hardest kind
        /// of bug to notice.
        case .failure(.nothingToOrder):
            show(Snackbar(
                title: "Nothing to Buy",
                message: "There was nothing in this order.",
                icon: "exclamationmark.triangle"
            ), in: context)
        }
    }
}
