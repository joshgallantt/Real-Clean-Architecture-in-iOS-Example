import Foundation
import Money
import Product
import Home
@testable import HomeUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A test says
/// what a shopper saw and tapped, never which type drew it or how.
///
/// Only one thing is genuinely faked — `StubDrawHomeFeed`, standing in for `DrawHomeFeedUseCase`.
/// Everything between it and the screen is real: `HomeScreenViewModel` itself.
final class Shopper {
    private let drawHomeFeed = StubDrawHomeFeed()
    let navigation = StubNavigation()

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
        await settle()
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

// MARK: - The one thing faked

final class StubDrawHomeFeed: DrawHomeFeedUseCase, @unchecked Sendable {
    var result: Result<HomeFeed, HomeError> = .failure(.unavailable)
    private(set) var callCount = 0

    func callAsFunction() async -> Result<HomeFeed, HomeError> {
        callCount += 1
        return result
    }
}

@MainActor
/// The app layer conforms `Navigator` to this. Home only ever opens a product or a category's
/// results, so that is all the test needs to know about.
final class StubNavigation: HomeNavigation {
    private(set) var openedProducts: [ProductID] = []
    private(set) var openedCatalogs: [CatalogFilter] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product.id) }
    }

    nonisolated func openCatalog(filter: CatalogFilter) {
        MainActor.assumeIsolated { openedCatalogs.append(filter) }
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func products(
    _ ids: ClosedRange<Int>,
    category: String,
    availability: Availability = .inStock(remaining: 10)
) -> [Product] {
    ids.map { Product.fixture(id: $0, category: category, availability: availability) }
}

extension Product {
    static func fixture(
        id: Int,
        category: String = "beauty",
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: category),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}

/// Test-fixture categories only — production code never extends a domain type (see
/// `presentation-models-not-domain-extensions`), but a domain type inside a test fixture is fine.
extension ProductCategory {
    static let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
    static let fragrances = ProductCategory(id: CategoryID(rawValue: "fragrances"), name: "Fragrances")
    static let furniture = ProductCategory(id: CategoryID(rawValue: "furniture"), name: "Furniture")
}
