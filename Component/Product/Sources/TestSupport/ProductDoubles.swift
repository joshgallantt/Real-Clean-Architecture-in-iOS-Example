import Foundation
import Money
import Product

/// Stand-ins and builders for the protocols and types this component declares.
///
/// Winters, Manshreck & Wright, *Software Engineering at Google* (2020), Ch. 13
/// — Test Doubles: the fake belongs to whoever owns the API. Product is the
/// component that shows why. Before this file, `LookUpProductsUseCase` had four
/// stand-ins, in four packages, none of which knew about the others:
/// two identical but for a way to make the shop unreachable, one that answered
/// with a canned result, one that modelled a shop with sold-out stock. Renaming
/// them so they no longer clashed — which is what a rule about names can ask
/// for — left all four exactly where they were.
///
/// They are side by side here now. Two of them merged on sight. The other two
/// model genuinely different things and are left as two, which is a decision
/// somebody can now see and argue with rather than one nobody knew was being
/// made.

// MARK: - Builders

/// Written twenty times over across this repository before it lived here.
public func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    /// The union of the four variants that had grown separately: one exposed
    /// availability, one a price, one a category, one none of them. Which is
    /// the argument for a single fixture in the first place — each caller had
    /// widened its own copy for its own test and nobody else got the benefit.
    public static func fixture(
        id: Int,
        price: Decimal = 9.99,
        category: String = "beauty",
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: category),
            price: Money(amount: price, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}

/// One thing the shop has, said the way a shopper would describe finding it.
public struct OnTheShelf {
    public let product: Product

    public var id: ProductID { product.id }

    public init(product: Product) {
        self.product = product
    }
}

// MARK: - Looking products up

/// A shop with stock, which can also be made unreachable.
///
/// The merge of two: Bag's copy could refuse to answer and StockAlert's could
/// not, and they were otherwise the same character for character.
public final class StubCatalog: LookUpProductsUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var _stock: [OnTheShelf] = []
    private var _cannotBeReached = false
    private var _asked: [[ProductID]] = []

    public init() {}

    public var stock: [OnTheShelf] {
        get { lock.withLock { _stock } }
        set { lock.withLock { _stock = newValue } }
    }

    /// Told apart from a shop that answers with nothing, because the two mean
    /// opposite things: one has stopped selling everything, the other has said
    /// nothing at all.
    public var cannotBeReached: Bool {
        get { lock.withLock { _cannotBeReached } }
        set { lock.withLock { _cannotBeReached = newValue } }
    }

    public var asked: [[ProductID]] { lock.withLock { _asked } }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        lock.withLock {
            _asked.append(ids)
            guard !_cannotBeReached else { return .failure(.unavailable) }
            let wanted = Set(ids)
            return .success(_stock.filter { wanted.contains($0.id) }.map(\.product))
        }
    }
}

/// Answers whatever it was told to, and remembers what it was asked. Kept apart
/// from `StubCatalog` deliberately: this one is about the answer, that one is
/// about the shop, and a test reads differently depending on which it needs.
public final class StubLookUpProducts: LookUpProductsUseCase, @unchecked Sendable {
    public var result: Result<[Product], ProductError> = .success([])
    public private(set) var asked: [[ProductID]] = []

    public init() {}

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        asked.append(ids)
        return result
    }
}

/// A shop that knows what it still sells and what it has run out of — the two
/// facts a wishlist has to tell apart.
public final class StubShop: LookUpProductsUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var _stillSells: Set<ProductID> = []
    private var _cannotBeReached = false
    private var _asked: [[ProductID]] = []
    private var _soldOut: Set<ProductID> = []

    public init() {}

    public var stillSells: Set<ProductID> {
        get { lock.withLock { _stillSells } }
        set { lock.withLock { _stillSells = newValue } }
    }

    public var cannotBeReached: Bool {
        get { lock.withLock { _cannotBeReached } }
        set { lock.withLock { _cannotBeReached = newValue } }
    }

    public var asked: [[ProductID]] { lock.withLock { _asked } }

    public func sells(_ ids: Int...) {
        stillSells = Set(ids.map(pid))
    }

    /// What it has, and how much of it. A shopper's two alert lists are told
    /// apart by exactly this.
    public var soldOut: Set<ProductID> {
        get { lock.withLock { _soldOut } }
        set { lock.withLock { _soldOut = newValue } }
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        lock.withLock {
            _asked.append(ids)
            guard !_cannotBeReached else { return .failure(.unavailable) }
            return .success(
                ids.filter { _stillSells.contains($0) }.map {
                    Product.fixture(
                        id: $0.rawValue,
                        availability: _soldOut.contains($0) ? .outOfStock : .inStock(remaining: 10)
                    )
                }
            )
        }
    }
}

// MARK: - Browsing

@MainActor
public final class StubBrowseCatalog: BrowseCatalogUseCase, @unchecked Sendable {
    public var result: Result<[Product], ProductError> = .success([])
    public private(set) var queries: [CatalogQuery] = []

    public init() {}

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        return result
    }
}

/// Answers differently per category, for a screen that draws several at once.
public final class StubBrowseCatalogByCategory: BrowseCatalogUseCase, @unchecked Sendable {
    public var resultsByCategory: [CategoryID: Result<[Product], ProductError>] = [:]
    public private(set) var queries: [CatalogQuery] = []

    public init() {}

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        guard case .category(let category) = query.filter else { return .success([]) }
        return resultsByCategory[category.id] ?? .success([])
    }
}

/// Records that it was asked, as well as answering. The merge of two copies,
/// one of which counted its calls and one of which did not — and the count is
/// the only reason a test would reach for this rather than a plain answer.
///
/// Not `@MainActor`, though one of the two copies was. Isolation that suited
/// the package which happened to write it stops the double being usable as a
/// default argument anywhere nonisolated — a constraint the protocol never
/// asked for, inherited from whoever got there first.
public final class SpyBrowseCategories: BrowseCategoriesUseCase, @unchecked Sendable {
    public var result: Result<[ProductCategory], ProductError> = .success([])
    public private(set) var callCount = 0

    public init() {}

    public func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        callCount += 1
        return result
    }
}

@MainActor
public final class StubViewProduct: ViewProductUseCase, @unchecked Sendable {
    public var result: Result<Product, ProductError> = .success(.fixture(id: 1))
    public private(set) var calls: [ProductID] = []

    public init() {}

    public func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        calls.append(id)
        return result
    }
}
