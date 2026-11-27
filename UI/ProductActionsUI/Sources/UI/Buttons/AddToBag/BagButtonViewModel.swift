import Combine
import Foundation
import Bag
import Product
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
///
public final class BagButtonViewModel {
    private(set) var quantity = 0

    private let product: Product
    private let observeBag: ObserveBagUseCase
    private let setBagItem: SetBagItemUseCase
    private let navigation: ProductActionsNavigation
    private let snackbarPresenter: SnackbarPresenting
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(
        product: Product,
        observeBag: ObserveBagUseCase,
        setBagItem: SetBagItemUseCase,
        navigation: ProductActionsNavigation,
        snackbarPresenter: SnackbarPresenting,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.product = product
        self.observeBag = observeBag
        self.setBagItem = setBagItem
        self.navigation = navigation
        self.snackbarPresenter = snackbarPresenter
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// Subscribing happens here rather than in `init`. See `WishlistButtonViewModel`:
    /// `@State` builds its initial value on every view initialisation, and this
    /// button is built once per product card.
    func onAppear() {
        guard cancellables.isEmpty else { return }

        let productId = product.id
        observeBag()
            .map { $0.quantity(of: productId) }
            .removeDuplicates()
            .sink { [weak self] value in
                self?.quantity = value
            }
            .store(in: &cancellables)
    }

    /// `ProductActionsUIDI` only builds a bag button for something the shop can supply, so this is not a
    /// second decision about which button to be. It is the one thing a bag button must never do:
    /// put something the shop cannot supply into a shopper's bag. What to offer instead belongs to
    /// `StockAlertButtonViewModel`, which can actually keep the promise it makes.
    func didTap(in context: TrackingContext) {
        guard product.availability.isAvailable else { return }
        trackElementInteraction(ProductActionsTrackingPlan.addToBag, about: item, in: context)
        addToBag(in: context)
    }

    /// One of this product, at the price the shopper is looking at — what a tap puts in the bag.
    private var item: TrackedItem { TrackedProduct.item(product) }

    private func addToBag(in context: TrackingContext) {
        /// One more than the bag holds, at the price the shopper is looking at. What is reported
        /// is the one that was added, not the line it left behind.
        let one = BagItem(productId: product.id, quantity: 1, lastKnownPrice: product.price, dateAdded: Date())
        setBagItem(one.withQuantity(quantity + 1))
        trackEvent(added(one, in: context))

        let snackbar = Snackbar(
            title: "In the Bag",
            message: "It'll be there when you're ready.",
            icon: "bag.fill",
            action: .view { [navigation, trackElementInteraction] in
                trackElementInteraction(ProductActionsTrackingPlan.viewBag, in: context)
                navigation.switchToBagTab()
            }
        )
        trackElementView(snackbar.trackingName, about: item, in: context)
        snackbarPresenter.show(snackbar)
    }

    /// The product added, read off the line the bag was handed — its price and how many — so a
    /// report and the bag cannot disagree about what a tap put in.
    private func added(_ line: BagItem, in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(
            name: .productAdded,
            context: context,
            items: [TrackedProduct.item(product, price: line.lastKnownPrice, quantity: line.quantity)],
            properties: [:]
        )
    }
}
