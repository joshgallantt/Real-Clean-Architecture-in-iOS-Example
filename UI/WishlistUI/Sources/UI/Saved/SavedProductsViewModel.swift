import Combine
import Foundation
import Product
import SnackbarUI
import Wishlist
import ProductUI
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 7 — Single Responsibility Principle: one job — the shopper's faves, filled in from
/// the catalog a page at a time. A wishlist holds ids and nothing else, so what each one is called
/// and what it costs today is asked of the shop here, and only for as much of the list as has been
/// reached.
public final class SavedProductsViewModel {
    /// Carries the cancellation: a fresh load replaces the one before it.
    @ObservationIgnored private var hydrationTask: Task<Void, Never>?

    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false

    private let pageSize: Int
    private let observeWishlist: ObserveWishlistUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase
    private let navigation: WishlistNavigation
    private let snackbar: SnackbarPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let cardTracking: ProductCardTracking

    private var cancellables = Set<AnyCancellable>()
    private var saved: [ProductID] = []
    private var cache: [ProductID: Product] = [:]
    private var loadedCount: Int

    public init(
        observeWishlist: ObserveWishlistUseCase,
        lookUpProducts: LookUpProductsUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        navigation: WishlistNavigation,
        snackbar: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        pageSize: Int
    ) {
        self.observeWishlist = observeWishlist
        self.lookUpProducts = lookUpProducts
        self.setProductIsWishlisted = setProductIsWishlisted
        self.navigation = navigation
        self.snackbar = snackbar
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.cardTracking = ProductCardTracking(trackElementView: trackElementView, trackElementInteraction: trackElementInteraction)
        self.pageSize = pageSize
        self.loadedCount = pageSize
    }

    var isEmpty: Bool { products.isEmpty }

    /// How many belong on this list, which is not how many a carousel shows: a row shows a handful
    /// and the heading still says how many there are altogether. Counted from what the shopper
    /// holds, so it is right before a single product has been fetched.
    var savedCount: Int { saved.count }

    /// Everything the shopper would lose, taken from the list as it is drawn.
    func didConfirmClear(in context: TrackingContext) {
        let losing = products.map(\.id)
        guard !losing.isEmpty else { return }
        trackElementInteraction(WishlistTrackingPlan.clear, about: WishlistTrackingPlan.item(WishlistTrackingPlan.faves), in: context)
        inFlight = Task { [setProductIsWishlisted] in
            for productId in losing {
                await setProductIsWishlisted(productId: productId, isWishlisted: false)
            }
        }
    }

    // MARK: - What the shopper saw and did

    /// Only on the list's own screen. On the tab this list is one of several, and the tab's view
    /// is the tab's to report.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func didSee(_ product: Product, in context: TrackingContext) {
        cardTracking.seen(product, in: context)
    }

    /// The card is reported where it was — which list, which position — and then opened. Opening it
    /// is the view model's to do, so no screen can open a product without saying so.
    func didSelect(_ product: Product, in context: TrackingContext) {
        cardTracking.selected(product, in: context)
        navigation.openProductDetails(product: product)
    }

    private func show(_ snackbar: Snackbar, in context: TrackingContext) {
        trackElementView(snackbar.trackingName, in: context)
        self.snackbar.show(snackbar)
    }

    func onAppear(in context: TrackingContext) {
        guard cancellables.isEmpty else { return }

        observeWishlist()
            .sink { [weak self] wishlist in
                self?.savedChanged(wishlist.items.map(\.productId), in: context)
            }
            .store(in: &cancellables)
    }

    /// Told about every card as the grid lays it out. Only the last one means anything: the shopper
    /// has reached the end of what is loaded, so the next page is worth fetching.
    func didLayOut(_ product: Product, in context: TrackingContext) {
        guard product.id == products.last?.id else { return }
        loadNextPage(in: context)
    }

    private func loadNextPage(in context: TrackingContext) {
        guard loadedCount < saved.count, !isLoading, !isLoadingMore else { return }
        loadedCount += pageSize
        hydrate(isPaging: true, in: context)
    }

    private func savedChanged(_ ids: [ProductID], in context: TrackingContext) {
        saved = ids

        let held = Set(ids)
        cache = cache.filter { held.contains($0.key) }

        hydrate(isPaging: false, in: context)
    }

    private func hydrate(isPaging: Bool, in context: TrackingContext) {
        hydrationTask?.cancel()

        let window = Array(saved.prefix(loadedCount))
        let missing = window.filter { cache[$0] == nil }

        guard !missing.isEmpty else {
            isLoading = false
            isLoadingMore = false
            products = showing(window)
            return
        }

        if isPaging {
            isLoadingMore = true
        } else {
            isLoading = true
        }

        let task = Task { [weak self] in
            guard let self else { return }
            let result = await self.lookUpProducts(ids: missing)
            guard !Task.isCancelled else { return }

            switch result {
            case .success(let fetched):
                for product in fetched {
                    self.cache[product.id] = product
                }

            case .failure:
                self.show(Snackbar(
                    title: "Faves Won't Load",
                    message: "Check your signal and give it another go.",
                    icon: "wifi.exclamationmark",
                    action: .retry { [weak self] in self?.hydrate(isPaging: isPaging, in: context) }
                ), in: context)
            }

            self.products = self.showing(window)
            self.isLoading = false
            self.isLoadingMore = false
        }
        hydrationTask = task
        inFlight = task
    }

    private func showing(_ window: [ProductID]) -> [Product] {
        window.compactMap { cache[$0] }
    }
}
