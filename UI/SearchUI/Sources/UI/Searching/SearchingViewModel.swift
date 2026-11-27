import Foundation
import Product
import SearchHistory
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
public final class SearchingViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var history = SearchHistory()
    private(set) var suggestions: [Product] = []
    private(set) var isSuggesting: Bool = false

    private let getSearchHistory: GetSearchHistoryUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let browseCatalog: BrowseCatalogUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        getSearchHistory: GetSearchHistoryUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        browseCatalog: BrowseCatalogUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.getSearchHistory = getSearchHistory
        self.clearSearchHistory = clearSearchHistory
        self.browseCatalog = browseCatalog
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
    }

    func onAppear() async {
        history = getSearchHistory()
    }

    func queryChanged(_ typed: String) {
        inFlight?.cancel()

        guard let term = SearchTerm(typed) else {
            suggestions = []
            return
        }

        inFlight = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            isSuggesting = true
            defer { isSuggesting = false }

            if case .success(let products) = await browseCatalog(matching: .search(term, page: 0, pageSize: 10)) {
                guard !Task.isCancelled else { return }
                suggestions = products
            }
        }
    }

    func clearHistory(in context: TrackingContext) {
        trackElementInteraction(SearchTrackingPlan.clearHistory, in: context)
        clearSearchHistory()
        history = getSearchHistory()
    }

    // MARK: - What the shopper saw and picked

    /// Where a row sits — which list, which position — arrives with it, set by the list that drew
    /// it, so a view model never has to count.
    func didSee(_ term: SearchTerm, in context: TrackingContext) {
        trackElementView(SearchTrackingPlan.recentSearchRow, about: SearchTrackingPlan.item(term), in: context)
    }

    func didSelect(_ term: SearchTerm, in context: TrackingContext) {
        trackElementInteraction(SearchTrackingPlan.recentSearchRow, about: SearchTrackingPlan.item(term), in: context)
    }

    func didSee(_ suggestion: Product, in context: TrackingContext) {
        trackElementView(SearchTrackingPlan.suggestionRow, about: TrackedProduct.item(suggestion), in: context)
    }

    func didSelect(_ suggestion: Product, in context: TrackingContext) {
        trackElementInteraction(SearchTrackingPlan.suggestionRow, about: TrackedProduct.item(suggestion), in: context)
    }
}
