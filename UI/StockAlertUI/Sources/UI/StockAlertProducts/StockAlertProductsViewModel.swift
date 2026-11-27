import Combine
import Foundation
import Product
import SnackbarUI
import StockAlert
import ProductUI
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: it asks one use
/// case for the products a shopper has alerts on and publishes what came back. Which of them have
/// come back, and so which come first, is not decided here — each product says so itself, and the
/// domain has already put them in order.
public final class StockAlertProductsViewModel {
    /// Carries the cancellation: a fresh load replaces the one before it.
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

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

    private let getStockAlertProducts: GetStockAlertProductsUseCase
    private let observeStockAlerts: ObserveStockAlertsUseCase
    private let setProductStockAlert: SetProductStockAlertUseCase
    private let navigation: StockAlertNavigation
    private let snackbar: SnackbarPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let cardTracking: ProductCardTracking

    private var cancellables = Set<AnyCancellable>()

    public init(
        getStockAlertProducts: GetStockAlertProductsUseCase,
        observeStockAlerts: ObserveStockAlertsUseCase,
        setProductStockAlert: SetProductStockAlertUseCase,
        navigation: StockAlertNavigation,
        snackbar: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.getStockAlertProducts = getStockAlertProducts
        self.observeStockAlerts = observeStockAlerts
        self.setProductStockAlert = setProductStockAlert
        self.navigation = navigation
        self.snackbar = snackbar
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.cardTracking = ProductCardTracking(trackElementView: trackElementView, trackElementInteraction: trackElementInteraction)
    }

    var isEmpty: Bool { products.isEmpty }

    var count: Int { products.count }

    /// What a shopper calls this list, wherever it is headed — above its row on the tab and across
    /// the top of its own screen.
    let title = "Stock Alerts"

    /// The alerts are watched, but only as a reason to ask again. What is *on* this list depends on
    /// what the shop still sells as well as what was asked, and only the use case knows both.
    /// `async` so the list can await it from `.task`: SwiftUI then owns the load
    /// for as long as the row is on screen and cancels it on the way out. The two
    /// synchronous callers below — a change in what was asked, and the retry
    /// button — go through `startReloading(in:)`, which is where the handle earns its
    /// keep.
    func onAppear(in context: TrackingContext) async {
        if cancellables.isEmpty {
            observeStockAlerts()
                .removeDuplicates()
                .sink { [weak self] _ in self?.startReloading(in: context) }
                .store(in: &cancellables)
        }

        await reload(in: context)
    }

    /// Every alert on the list as it is drawn, back or not.
    func didConfirmClear(in context: TrackingContext) {
        let losing = products.map(\.id)
        guard !losing.isEmpty else { return }
        trackElementInteraction(StockAlertTrackingPlan.clear, about: StockAlertTrackingPlan.listItem, in: context)
        inFlight = Task { [setProductStockAlert] in
            for productId in losing {
                await setProductStockAlert(productId: productId, isOn: false)
            }
        }
    }

    /// View All opens the list's own screen; what the tap is about is the list.
    func didTapViewAll(in context: TrackingContext) {
        trackElementInteraction(StockAlertTrackingPlan.viewAll, about: StockAlertTrackingPlan.listItem, in: context)
        navigation.openAllStockAlerts()
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

    private func startReloading(in context: TrackingContext) {
        reloadTask?.cancel()
        isLoading = true

        let task = Task { [weak self] in
            guard let self else { return }
            await self.reload(in: context)
        }
        reloadTask = task
        inFlight = task
    }

    /// `context` is where the list is drawn, handed down from the view that asked for the load, so
    /// a snackbar after a load that failed is reported on the screen it was seen on.
    private func reload(in context: TrackingContext) async {
        isLoading = true

        let result = await getStockAlertProducts()
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let loaded):
            products = loaded

        /// The list is left as it was. A dropped connection is not evidence that a shopper has
        /// stopped waiting on anything, and emptying the row would say that it is.
        case .failure:
            show(Snackbar(
                title: "Stock Alerts Won't Load",
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in self?.startReloading(in: context) }
            ), in: context)
        }

        isLoading = false
    }
}
