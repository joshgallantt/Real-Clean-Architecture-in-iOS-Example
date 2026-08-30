import Foundation
import HomeTestSupport
import Money
import Product
import Home
import ProductTestSupport
@testable import HomeUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A test says
/// what a shopper saw and tapped, never which type drew it or how.
///
/// Only one thing is genuinely faked — `StubDrawHomeFeed`, standing in for `DrawHomeFeedUseCase`.
/// Everything between it and the screen is real: `HomeScreenViewModel` itself.
final class Shopper {
    private let drawHomeFeed = StubDrawHomeFeed()
    let navigation = StubHomeNavigation()

    private var home: HomeScreenViewModel?
    private var carousels: [HomeCarousel] = []

    // MARK: - What the shop sells

    func sells(_ category: ProductCategory, _ products: [Product]) {
        carousels.append(HomeCarousel(category: category, products: products))
        drawHomeFeed.result = .success(HomeFeed(carousels: carousels)!)
    }

    func theShopCannotDrawAFeed() {
        drawHomeFeed.result = .failure(.unavailable)
    }

    // MARK: - What a shopper does

    @discardableResult
    func opensHome() async -> Shopper {
        let viewModel = home ?? HomeScreenViewModel(drawHomeFeed: drawHomeFeed, navigation: navigation)
        home = viewModel
        await viewModel.onAppear()
        return self
    }

    func selects(_ product: Product) {
        home?.didSelect(product)
    }

    func tapsViewAll(for category: ProductCategory) {
        guard let carousel = carouselsShown.first(where: { $0.category.id == category.id }) else { return }
        home?.didTapViewAll(for: carousel)
    }

    func triesAgain() async {
        home?.didTapRetry()
        await home?.inFlight?.value
    }

    // MARK: - What a shopper sees

    /// One carousel per category the feed drew, in the order it drew them. Empty whenever Home has
    /// drawn nothing, whatever the reason — `isOfferedAnotherGo` is what says a shopper is looking
    /// at the failure screen rather than at carousels.
    var carouselsShown: [HomeCarousel] {
        guard let home, case .loaded(let feed) = home.state else { return [] }
        return feed.carousels
    }

    /// Home has nothing to show and says so, with a way to try again.
    var isOfferedAnotherGo: Bool {
        guard let home else { return false }
        if case .error = home.state { return true }
        return false
    }

    var drawAttempts: Int { drawHomeFeed.callCount }
}
