import Foundation
import Money
import Product
import Home
import HomeDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A test says
/// what a shopper's Home drew, never which type stored it or how it chose it.
///
/// Only one thing is genuinely faked — `Shop`, standing in for `ProductRepository`. Everything
/// between it and the draw is real: `DefaultBrowseCatalogUseCase`, `DefaultBrowseCategoriesUseCase`
/// and `HomeDI`'s own use case.
final class Shopper {
    let shop = Shop()
    private let di: HomeDI

    init() {
        di = HomeDI(
            browseCatalog: DefaultBrowseCatalogUseCase(productRepository: shop),
            browseCategories: DefaultBrowseCategoriesUseCase(productRepository: shop)
        )
    }

    // MARK: - What the shop sells

    func sells(_ category: ProductCategory, _ products: [Product]) {
        shop.sell(category, products)
    }

    // MARK: - What a shopper does

    private var feed: HomeFeed?
    private(set) var homeCouldNotBeDrawn = false

    @discardableResult
    func opensHome() async -> Shopper {
        switch await di.drawHomeFeedUseCase() {
        case .success(let feed):
            self.feed = feed
            homeCouldNotBeDrawn = false
        case .failure:
            self.feed = nil
            homeCouldNotBeDrawn = true
        }
        return self
    }

    // MARK: - What a shopper sees

    var carouselsShown: [HomeCarousel] { feed?.carousels ?? [] }
}

// MARK: - The one thing faked

/// Fowler, *PoEAA* (2002), Ch. 13 — Repository: a working double of a shopper's shop, not a store
/// of canned answers per call. Categories and products are added the way a shop stocks a shelf, and
/// the real use cases read them back.
final class Shop: ProductRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _categories: [ProductCategory] = []
    private var _productsByCategory: [CategoryID: [Product]] = [:]
    private var _cannotBeReached = false
    private var _unreachableCategories: Set<CategoryID> = []
    private var _categoryProductRequests: [CategoryID] = []

    // MARK: - Test control

    var cannotBeReached: Bool {
        get { lock.withLock { _cannotBeReached } }
        set { lock.withLock { _cannotBeReached = newValue } }
    }

    func makeUnreachable(_ categoryId: CategoryID) {
        lock.withLock { _ = _unreachableCategories.insert(categoryId) }
    }

    var categoryProductRequests: [CategoryID] { lock.withLock { _categoryProductRequests } }

    func sell(_ category: ProductCategory, _ products: [Product]) {
        lock.withLock {
            if !_categories.contains(category) { _categories.append(category) }
            _productsByCategory[category.id] = products
        }
    }

    // MARK: - ProductRepository

    func getCategories() async -> Result<[ProductCategory], ProductError> {
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
    static let toys = ProductCategory(id: CategoryID(rawValue: "toys"), name: "Toys")
    static let books = ProductCategory(id: CategoryID(rawValue: "books"), name: "Books")
}
