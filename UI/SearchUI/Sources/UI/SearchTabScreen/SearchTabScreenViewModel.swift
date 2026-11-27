import Foundation
import Product
import SearchHistory
import SnackbarUI
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class SearchTabScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    var query: String = ""
    var isSearchActive: Bool = false
    private(set) var categories: [ProductCategory] = []

    private let browseCategories: BrowseCategoriesUseCase
    private let recordSearch: RecordSearchUseCase
    private let snackbar: SnackbarPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        browseCategories: BrowseCategoriesUseCase,
        recordSearch: RecordSearchUseCase,
        snackbar: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.browseCategories = browseCategories
        self.recordSearch = recordSearch
        self.snackbar = snackbar
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// Every time the tab comes into view. Kept apart from `onAppear()`, whose guard skips loading
    /// once the categories are in — a guard that must never skip the visit too.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func onAppear(in context: TrackingContext) async {
        guard categories.isEmpty else { return }
        await loadCategories(in: context)
    }

    /// `context` is where the tab is drawn, handed down from the view that asked for the load, so
    /// a snackbar after a load that failed is reported on the screen it was seen on.
    private func loadCategories(in context: TrackingContext) async {
        switch await browseCategories() {
        case .success(let value):
            categories = value
        case .failure:
            show(Snackbar(
                title: "Nothing's Loading",
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    self?.inFlight = Task { await self?.loadCategories(in: context) }
                }
            ), in: context)
        }
    }

    /// A search is reported however it was made — typed and submitted, or a recent one tapped
    /// again. Both are the shopper asking the shop the same question.
    func didSubmitSearch(_ term: SearchTerm, in context: TrackingContext) {
        recordSearch(term)
        trackEvent(TrackingEvent(name: .productsSearched, context: context, items: [], properties: ["query": term.text]))
    }

    // MARK: - The categories list

    /// Where each row sits — All Products at the top, each category below it — arrives in `context`
    /// from the row itself, so nothing here has to count.
    func didSeeAllProducts(in context: TrackingContext) {
        trackElementView(SearchTrackingPlan.categoryRow, about: SearchTrackingPlan.allProducts, in: context)
    }

    func didSelectAllProducts(in context: TrackingContext) {
        trackElementInteraction(SearchTrackingPlan.categoryRow, about: SearchTrackingPlan.allProducts, in: context)
    }

    func didSee(_ category: ProductCategory, in context: TrackingContext) {
        trackElementView(SearchTrackingPlan.categoryRow, about: SearchTrackingPlan.item(category), in: context)
    }

    func didSelectCategory(_ category: ProductCategory, in context: TrackingContext) {
        trackElementInteraction(SearchTrackingPlan.categoryRow, about: SearchTrackingPlan.item(category), in: context)
    }

    private func show(_ snackbar: Snackbar, in context: TrackingContext) {
        trackElementView(snackbar.trackingName, in: context)
        self.snackbar.show(snackbar)
    }
}
