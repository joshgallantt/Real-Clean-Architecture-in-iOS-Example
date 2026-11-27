import Foundation
import Product
import SnackbarUI
import ProductUI
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class CatalogResultsViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    let filter: CatalogFilter
    private(set) var results: [Product] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false

    private let browseCatalog: BrowseCatalogUseCase
    private let snackbar: SnackbarPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let cardTracking: ProductCardTracking

    private let pageSize = 30
    private var page = 0
    private var hasMore = true

    public init(
        filter: CatalogFilter,
        browseCatalog: BrowseCatalogUseCase,
        snackbar: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.filter = filter
        self.browseCatalog = browseCatalog
        self.snackbar = snackbar
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.cardTracking = ProductCardTracking(trackElementView: trackElementView, trackElementInteraction: trackElementInteraction)
    }

    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    /// What these results are a list of. A card's position counts down the whole list, not the
    /// page — the grid holds every page loaded so far, so the thirty-first card is at 30 whichever
    /// page brought it.
    var list: TrackingContext.List { SearchTrackingPlan.results(filter, title: title) }

    func didSee(_ product: Product, in context: TrackingContext) {
        cardTracking.seen(product, in: context)
    }

    var title: String {
        switch filter {
        case .all: "All Products"
        case .search(let term): term.text
        case .category(let category): category.name
        }
    }

    var emptySearchText: String? {
        guard case .search(let term) = filter else { return nil }
        return term.text
    }

    func onAppear(in context: TrackingContext) async {
        guard results.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        await load(reset: true, in: context)
    }

    /// Told about every card as the grid lays it out. Only the last one means anything: the shopper
    /// has reached the end of what is loaded, so the next page is worth asking for.
    func didLayOut(_ product: Product, in context: TrackingContext) {
        guard product.id == results.last?.id else { return }
        inFlight = Task { await loadMore(in: context) }
    }

    func loadMore(in context: TrackingContext) async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        await load(reset: false, in: context)
    }

    /// `context` is where the results are drawn, handed down from the view that asked for the
    /// load, so a snackbar after a load that failed is reported on the screen it was seen on.
    private func load(reset: Bool, in context: TrackingContext) async {
        let nextPage = reset ? 0 : page + 1

        switch await browseCatalog(matching: CatalogQuery(filter: filter, page: nextPage, pageSize: pageSize)) {
        case .success(let value):
            results = reset ? value : results + value
            page = nextPage
            hasMore = value.count == pageSize
        case .failure:
            let snackbar = Snackbar(
                title: "Nothing's Loading",
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    self?.inFlight = Task { await self?.load(reset: reset, in: context) }
                }
            )
            trackElementView(snackbar.trackingName, in: context)
            self.snackbar.show(snackbar)
        }
    }

    func didSelect(_ product: Product, in context: TrackingContext) {
        cardTracking.selected(product, in: context)
    }
}
