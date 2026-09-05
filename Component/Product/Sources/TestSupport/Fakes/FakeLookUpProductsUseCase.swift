import Money
import Product
import Synchronization

/// A shop with stock, which can be made to run out of a thing or to be
/// unreachable altogether.
///
/// One stub for Bag, StockAlert and Wishlist. There had been two — a
/// `FakeLookUpProductsUseCase` handed its products and a `FakeLookUpProductsUseCase` that made them up from the
/// ids it was told it sells — with the same lock, the same `cannotBeReached`,
/// the same record of what it was asked and the same filtering. `stock` and
/// `sells(_:)` are the two ways in; everything after them is shared.
///
/// State lives in a `Mutex` rather than behind an `NSLock`, so the type is
/// `Sendable` because the compiler can see that it is. `@unchecked Sendable` is
/// a promise the compiler takes on trust and cannot check, which is worth
/// making where there is no alternative and worth removing where there is.
public final class FakeLookUpProductsUseCase: LookUpProductsUseCase {
    private struct State {
        var stock: [OnTheShelf] = []
        var soldOut: Set<ProductID> = []
        var cannotBeReached = false
        var asked: [[ProductID]] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var stock: [OnTheShelf] {
        get { state.withLock { $0.stock } }
        set { state.withLock { $0.stock = newValue } }
    }

    /// Told apart from a shop that answers with nothing, because the two mean
    /// opposite things: one has stopped selling everything, the other has said
    /// nothing at all.
    public var cannotBeReached: Bool {
        get { state.withLock { $0.cannotBeReached } }
        set { state.withLock { $0.cannotBeReached = newValue } }
    }

    /// What it has run out of. A shopper's two alert lists are told apart by
    /// exactly this, so it is a fact about the stock rather than a second shop.
    public var soldOut: Set<ProductID> {
        get { state.withLock { $0.soldOut } }
        set { state.withLock { $0.soldOut = newValue } }
    }

    public var asked: [[ProductID]] { state.withLock { $0.asked } }

    /// The shelf read as a set of ids, for a test that cares which things exist
    /// rather than what each one is.
    public var stillSells: Set<ProductID> {
        get { Set(stock.map(\.id)) }
        set { stock = newValue.sorted { $0.rawValue < $1.rawValue }.map { OnTheShelf(product: .fixture(id: $0.rawValue)) } }
    }

    public func sells(_ ids: Int...) {
        stillSells = Set(ids.map(pid))
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        state.withLock { state in
            state.asked.append(ids)
            guard !state.cannotBeReached else { return .failure(.unavailable) }
            let wanted = Set(ids)
            return .success(
                state.stock
                    .filter { wanted.contains($0.id) }
                    .map { shelf in
                        state.soldOut.contains(shelf.id) ? shelf.product.soldOut : shelf.product
                    }
            )
        }
    }
}

private extension Product {
    /// The same product, out of stock. Rebuilt rather than replaced by a
    /// fixture, so a stub told to run out of something a test supplied still
    /// answers with that thing.
    var soldOut: Product {
        Product(
            id: id,
            title: title,
            description: description,
            category: category,
            price: price,
            rating: rating,
            availability: .outOfStock,
            brand: brand,
            thumbnail: thumbnail,
            images: images
        )
    }
}
