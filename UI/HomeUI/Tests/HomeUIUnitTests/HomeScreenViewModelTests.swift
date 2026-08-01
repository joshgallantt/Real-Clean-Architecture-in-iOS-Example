import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("The home screen")
struct HomeScreenViewModelTests {
    private func makeViewModel(
        browseCatalog: StubBrowseCatalog = StubBrowseCatalog(),
        browseCategories: StubBrowseCategories = StubBrowseCategories(),
        navigation: StubNavigation = StubNavigation()
    ) -> HomeScreenViewModel {
        HomeScreenViewModel(
            browseCatalog: browseCatalog,
            browseCategories: browseCategories,
            navigation: navigation
        )
    }

    @Test("Before anything is asked of the shop, Home is loading")
    func startsLoading() {
        #expect(makeViewModel().state == .loading)
    }

    @Test("Appearing draws a carousel for each category that qualifies")
    func appearingDrawsACarouselPerQualifyingCategory() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...6, category: "beauty"))
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state.carousels.map(\.category.name) == ["Beauty"])
        #expect(viewModel.state.carousels.first?.products.map(\.id) == (1...6).map(pid))
        #expect(browseCatalog.queries.first?.pageSize == 10)
    }

    @Test(
        "A category needs at least 5 products to earn a carousel, and a carousel never shows more than 10",
        arguments: [
            (available: 0, expectedShown: nil),
            (available: 4, expectedShown: nil),
            (available: 5, expectedShown: 5),
            (available: 6, expectedShown: 6),
            (available: 15, expectedShown: 10)
        ] as [(available: Int, expectedShown: Int?)]
    )
    func floorAndCap(_ example: (available: Int, expectedShown: Int?)) async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty])
        let browseCatalog = StubBrowseCatalog()
        let stock = example.available > 0 ? products(1...example.available, category: "beauty") : []
        // The stub does not truncate to the requested page size, unlike a real repository — this
        // pins the cap as the view model's own rule rather than something merely inherited.
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(stock)
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)

        await viewModel.onAppear()

        if let expectedShown = example.expectedShown {
            #expect(viewModel.state.carousels.first?.products.count == expectedShown)
        } else {
            #expect(viewModel.state == .error)
        }
    }

    @Test("Appearing draws at most 3 categories, even when the shop offers more")
    func appearingDrawsAtMostThreeCategories() async {
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture]
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success(categories)
        let browseCatalog = StubBrowseCatalog()
        for category in categories {
            browseCatalog.resultsByCategory[category.id] = .success(products(1...6, category: category.id.rawValue))
        }
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state.carousels.count <= 3)
        let shown = Set(viewModel.state.carousels.map(\.category.id))
        #expect(shown.isSubset(of: Set(categories.map(\.id))))
    }

    @Test("A category that fails to load does not take down the categories that did")
    func aCategoryFailingToLoadIsDroppedSilently() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty, .fragrances])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...5, category: "beauty"))
        browseCatalog.resultsByCategory[.init(rawValue: "fragrances")] = .failure(.unavailable)
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state.carousels.map(\.category.name) == ["Beauty"])
    }

    @Test("If every category the feed tried fails to load, Home has nothing to draw")
    func everyCategoryFailingToLoadLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty, .fragrances])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .failure(.unavailable)
        browseCatalog.resultsByCategory[.init(rawValue: "fragrances")] = .failure(.unavailable)
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state == .error)
    }

    @Test("A shop that cannot even be asked for its categories leaves Home with nothing to draw")
    func cannotReachCategoriesLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .failure(.unavailable)
        let viewModel = makeViewModel(browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state == .error)
    }

    @Test("A shop with no categories to organise into leaves Home with nothing to draw")
    func noCategoriesLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([])
        let viewModel = makeViewModel(browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.state == .error)
    }

    @Test("Appearing again once something has already loaded asks nothing more")
    func appearingAgainOnceLoadedAsksNothingMore() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...5, category: "beauty"))
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(browseCategories.callCount == 1)
    }

    /// Only a loaded Home is settled. Coming back to one that had nothing to draw asks again, which
    /// is what having no `hasDrawnTheFeed` flag to consult amounts to.
    @Test("Appearing again after Home had nothing to draw asks the shop again")
    func appearingAgainAfterNothingToDrawAsksAgain() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .failure(.unavailable)
        let viewModel = makeViewModel(browseCategories: browseCategories)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(browseCategories.callCount == 2)
    }

    @Test("Trying again asks the shop again, and what succeeds this time is shown")
    func retryingAsksAgainAndShowsWhatSucceeds() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .failure(.unavailable)
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...5, category: "beauty"))
        let viewModel = makeViewModel(browseCatalog: browseCatalog, browseCategories: browseCategories)
        await viewModel.onAppear()

        browseCategories.result = .success([.beauty])
        viewModel.didTapRetry()
        await settle()

        #expect(browseCategories.callCount == 2)
        #expect(viewModel.state.carousels.map(\.category.name) == ["Beauty"])
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

@Suite("A home feed")
/// The invariant `HomeScreenState` leans on: `.loaded` cannot stand for a screen with nothing on it,
/// because a feed with no carousels cannot be built in the first place.
struct HomeFeedTests {
    @Test("A feed with no carousels is not a feed")
    func noCarouselsIsNotAFeed() {
        #expect(HomeFeed(carousels: []) == nil)
    }

    @Test("A feed keeps the carousels it was drawn with, in order")
    func keepsItsCarouselsInOrder() {
        let beauty = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
        let fragrances = HomeCarousel(category: .fragrances, products: products(101...105, category: "fragrances"))

        #expect(HomeFeed(carousels: [beauty, fragrances])?.carousels == [beauty, fragrances])
    }
}
