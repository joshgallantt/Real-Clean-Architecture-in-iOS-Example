import Foundation
import Product

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
