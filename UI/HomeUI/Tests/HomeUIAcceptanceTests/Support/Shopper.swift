import Foundation
import Money
import Product
@testable import HomeUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A test says what
/// a shopper saw and tapped, never which type stored it or how it shaped that state.
///
/// Only one thing is genuinely faked — `Shop`, standing in for `ProductRepository`. Everything
/// between it and the screen is real: `DefaultBrowseCatalogUseCase`, `DefaultBrowseCategoriesUseCase`
/// and `HomeScreenViewModel` itself.
final class Shopper {
    let shop = Shop()
    let navigation = StubNavigation()

    private var home: HomeScreenViewModel?

    // MARK: - What the shop sells

    func sells(_ category: ProductCategory, _ products: [Product]) {
        shop.sell(category, products)
    }

    // MARK: - What a shopper does

    @discardableResult
    func opensHome() async -> Shopper {
        let viewModel = home ?? HomeScreenViewModel(
            browseCatalog: DefaultBrowseCatalogUseCase(productRepository: shop),
            browseCategories: DefaultBrowseCategoriesUseCase(productRepository: shop),
            navigation: navigation
        )
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

    /// Home has nothing to show and says so, with a way to try again. A shop that cannot be reached
    /// and a shop with nothing worth drawing both land here.
    var isOfferedAnotherGo: Bool {
        guard let home else { return false }
        if case .error = home.state { return true }
        return false
    }
}

// MARK: - The one thing faked

/// Fowler, *PoEAA* (2002), Ch. 13 — Repository: a working double a shopper's shop, not a store of
/// canned answers per call. Categories and products are added the way a shop stocks a shelf, and the
/// real use cases read them back.
final class Shop: ProductRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _categories: [ProductCategory] = []
    private var _productsByCategory: [CategoryID: [Product]] = [:]
    private var _cannotBeReached = false
    private var _unreachableCategories: Set<CategoryID> = []
    private var _categoriesAskedCount = 0
    private var _categoryProductRequests: [CategoryID] = []

    // MARK: - Test control

    var cannotBeReached: Bool {
        get { lock.withLock { _cannotBeReached } }
        set { lock.withLock { _cannotBeReached = newValue } }
    }

    func makeUnreachable(_ categoryId: CategoryID) {
        lock.withLock { _ = _unreachableCategories.insert(categoryId) }
    }

    var categoriesAskedCount: Int { lock.withLock { _categoriesAskedCount } }
    var categoryProductRequests: [CategoryID] { lock.withLock { _categoryProductRequests } }

    func sell(_ category: ProductCategory, _ products: [Product]) {
        lock.withLock {
            if !_categories.contains(category) { _categories.append(category) }
            _productsByCategory[category.id] = products
        }
    }

    // MARK: - ProductRepository

    func getCategories() async -> Result<[ProductCategory], ProductError> {
        lock.withLock { _categoriesAskedCount += 1 }
        if cannotBeReached { return .failure(.unavailable) }
        return .success(lock.withLock { _categories })
    }

    func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        guard case .category(let category) = query.filter else { return .success([]) }
        lock.withLock { _categoryProductRequests.append(category.id) }
        if cannotBeReached { return .failure(.unavailable) }
        if lock.withLock({ _unreachableCategories.contains(category.id) }) { return .failure(.unavailable) }
        let all = lock.withLock { _productsByCategory[category.id] ?? [] }
        return .success(Array(all.prefix(query.pageSize)))
    }

    func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError> {
        .success([])
    }

    func getProduct(id: ProductID) async -> Result<Product, ProductError> {
        .failure(.notFound)
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
    static let kitchen = ProductCategory(id: CategoryID(rawValue: "kitchen"), name: "Kitchen")
    static let sports = ProductCategory(id: CategoryID(rawValue: "sports"), name: "Sports")
}
