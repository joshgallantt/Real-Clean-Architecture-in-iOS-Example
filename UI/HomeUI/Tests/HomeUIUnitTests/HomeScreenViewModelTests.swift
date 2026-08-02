import Foundation
import Testing
import Product
import Home
@testable import HomeUI

@MainActor
@Suite("The home screen")
struct HomeScreenViewModelTests {
    private func makeViewModel(
        drawHomeFeed: StubDrawHomeFeed = StubDrawHomeFeed(),
        navigation: StubNavigation = StubNavigation()
    ) -> HomeScreenViewModel {
        HomeScreenViewModel(drawHomeFeed: drawHomeFeed, navigation: navigation)
    }

    @Test("Before anything is asked of the shop, Home is loading")
    func startsLoading() {
        #expect(makeViewModel().state == .loading)
    }

    @Test("Appearing shows what the draw succeeded with")
    func appearingShowsWhatWasDrawn() async {
        let drawHomeFeed = StubDrawHomeFeed()
        let carousel = HomeCarousel(category: .beauty, products: products(1...6, category: "beauty"))
        drawHomeFeed.result = .success(HomeFeed(carousels: [carousel])!)
        let viewModel = makeViewModel(drawHomeFeed: drawHomeFeed)

        await viewModel.onAppear()

        #expect(viewModel.state.carousels == [carousel])
    }

    @Test("Appearing when the draw fails leaves Home with nothing to show")
    func appearingWhenTheDrawFailsShowsError() async {
        let drawHomeFeed = StubDrawHomeFeed()
        drawHomeFeed.result = .failure(.unavailable)
        let viewModel = makeViewModel(drawHomeFeed: drawHomeFeed)

        await viewModel.onAppear()

        #expect(viewModel.state == .error)
    }

    @Test("Appearing again once something has already loaded asks nothing more")
    func appearingAgainOnceLoadedAsksNothingMore() async {
        let drawHomeFeed = StubDrawHomeFeed()
        let carousel = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
        drawHomeFeed.result = .success(HomeFeed(carousels: [carousel])!)
        let viewModel = makeViewModel(drawHomeFeed: drawHomeFeed)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(drawHomeFeed.callCount == 1)
    }

    /// Only a loaded Home is settled. Coming back to one that had nothing to draw asks again, which
    /// is what having no `hasDrawnTheFeed` flag to consult amounts to.
    @Test("Appearing again after Home had nothing to draw asks the shop again")
    func appearingAgainAfterNothingToDrawAsksAgain() async {
        let drawHomeFeed = StubDrawHomeFeed()
        drawHomeFeed.result = .failure(.unavailable)
        let viewModel = makeViewModel(drawHomeFeed: drawHomeFeed)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(drawHomeFeed.callCount == 2)
    }

    @Test("Trying again asks for another draw, and what succeeds this time is shown")
    func retryingAsksAgainAndShowsWhatSucceeds() async {
        let drawHomeFeed = StubDrawHomeFeed()
        drawHomeFeed.result = .failure(.unavailable)
        let viewModel = makeViewModel(drawHomeFeed: drawHomeFeed)
        await viewModel.onAppear()
        let carousel = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
        drawHomeFeed.result = .success(HomeFeed(carousels: [carousel])!)

        viewModel.didTapRetry()
        await settle()

        #expect(drawHomeFeed.callCount == 2)
        #expect(viewModel.state.carousels == [carousel])
    }

    @Test("Selecting a product opens its details")
    func selectingAProductOpensItsDetails() async {
        let navigation = StubNavigation()
        let viewModel = makeViewModel(navigation: navigation)
        let product = Product.fixture(id: 1)

        viewModel.didSelect(product)

        #expect(navigation.openedProducts == [pid(1)])
    }

    @Test("Tapping View All opens that category's own results")
    func tappingViewAllOpensThatCategorysOwnResults() async {
        let navigation = StubNavigation()
        let viewModel = makeViewModel(navigation: navigation)
        let carousel = HomeCarousel(category: .fragrances, products: products(101...105, category: "fragrances"))

        viewModel.didTapViewAll(for: carousel)

        #expect(navigation.openedCatalogs == [.category(.fragrances)])
    }
}
