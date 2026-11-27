import Foundation
import Home
import Product
import ProductUI
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the one capability it calls.
/// What a category needs to earn a carousel, and how many carousels Home draws, are
/// `DrawHomeFeedUseCase`'s business, not this screen's.
public final class HomeScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var state: HomeScreenState = .loading

    private let drawHomeFeed: DrawHomeFeedUseCase
    private let navigation: HomeNavigation
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let cardTracking: ProductCardTracking

    public init(
        drawHomeFeed: DrawHomeFeedUseCase,
        navigation: HomeNavigation,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.drawHomeFeed = drawHomeFeed
        self.navigation = navigation
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.cardTracking = ProductCardTracking(trackElementView: trackElementView, trackElementInteraction: trackElementInteraction)
    }

    /// Every time Home comes into view, not only the first: a shopper coming back to the tab is a
    /// visit. Kept apart from `onAppear()`, whose guard skips the load once the feed is drawn — a
    /// guard that must never skip the visit too.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func onAppear() async {
        if case .loaded = state { return }
        await load()
    }

    func didTapRetry(in context: TrackingContext) {
        trackElementInteraction(HomeTrackingPlan.retry, in: context)
        inFlight = Task { await load() }
    }

    private func load() async {
        state = .loading

        switch await drawHomeFeed() {
        case .success(let feed):
            state = .loaded(feed)
        case .failure:
            state = .error
        }
    }

    /// Which carousel and where in it are part of the tap — the third card in Beauty and the first
    /// card in Toys are different decisions about the same feed — and both arrive in `context`,
    /// from the carousel and the card that drew it.
    func didSelect(_ product: Product, in context: TrackingContext) {
        cardTracking.selected(product, in: context)
        navigation.openProductDetails(product: product)
    }

    func didSee(_ product: Product, in context: TrackingContext) {
        cardTracking.seen(product, in: context)
    }

    func didTapViewAll(for carousel: HomeCarousel, in context: TrackingContext) {
        trackElementInteraction(HomeTrackingPlan.viewAll, about: HomeTrackingPlan.item(carousel.category), in: context)
        navigation.openCatalog(filter: .category(carousel.category))
    }
}
