import Foundation
import HomeTestSupport
import ProductTestSupport
import Testing
import Product
import Home
import Tracking
import TrackingTestSupport
import TrackingUI
@testable import HomeUI
@testable import HomeUITestSupport

@MainActor
@Suite("What Home tells the shop")
/// Where each event happened arrives as the context the view read — the screen, or a card's
/// position in a carousel — so these say what Home reports, given where.
struct TrackingHomeTests {
    private let screen = "home"
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let beauty = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
    private let beautyList = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    private func makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase) -> HomeScreenViewModel {
        HomeScreenViewModel(
            drawHomeFeed: drawHomeFeed,
            navigation: SpyHomeNavigation(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    @Test("Home coming into view is a screen view, every time it comes into view")
    func everyAppearanceIsAView() {
        let viewModel = makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase())

        viewModel.didAppear(in: .screen(screen))
        viewModel.didAppear(in: .screen(screen))

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen(screen), items: [], properties: [:]), TrackingEvent(name: .screenViewed, context: .screen(screen), items: [], properties: [:])])
    }

    @Test("Coming back to a Home that has already loaded is still a visit, though nothing is asked of the shop")
    func loadedHomeStillCounts() async {
        let draw = SpyDrawHomeFeedUseCase()
        draw.result = .success(HomeFeed(carousels: [beauty])!)
        let viewModel = makeViewModel(drawHomeFeed: draw)
        viewModel.didAppear(in: .screen(screen))
        await viewModel.onAppear()

        viewModel.didAppear(in: .screen(screen))
        await viewModel.onAppear()

        #expect(screens.events.count == 2)
        #expect(draw.callCount == 1)
    }

    @Test("A card seen in a carousel is an impression in that carousel, at its position")
    func cardSeen() {
        let product = beauty.products[2]
        let where_ = TrackingContext.list(screen, beautyList, index: 2)

        makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase()).didSee(product, in: where_)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
    }

    @Test("A card tapped in a carousel is a tap in that carousel, at its position")
    func cardTapped() {
        let product = beauty.products[3]
        let where_ = TrackingContext.list(screen, beautyList, index: 3)

        makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase()).didSelect(product, in: where_)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
    }

    @Test("Each carousel is its own list, named for its category")
    func carouselList() {
        #expect(HomeTrackingPlan.list(beauty) == beautyList)
    }

    @Test("View All is a tap on the screen about the category it opens")
    func viewAll() {
        makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase()).didTapViewAll(for: beauty, in: .screen(screen))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: .screen(screen), items: [.content(id: "beauty", name: "Beauty")], properties: ["element": "view_all"])])
    }

    @Test("Trying again is a tap about nothing in particular")
    func retry() {
        makeViewModel(drawHomeFeed: SpyDrawHomeFeedUseCase()).didTapRetry(in: .screen(screen))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: .screen(screen), items: [], properties: ["element": "retry"])])
    }
}
