import Money
import Product
import Synchronization

/// A shop that knows what it still sells and what it has run out of — the two
/// facts a wishlist has to tell apart.
///
/// State lives in a `Mutex`, so the compiler can see this is safe to share
/// rather than being asked to take it on trust.
public final class StubShop: LookUpProductsUseCase {
    private struct State {
        var stillSells: Set<ProductID> = []
        var soldOut: Set<ProductID> = []
        var cannotBeReached = false
        var asked: [[ProductID]] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var stillSells: Set<ProductID> {
        get { state.withLock { $0.stillSells } }
        set { state.withLock { $0.stillSells = newValue } }
    }

    public var cannotBeReached: Bool {
        get { state.withLock { $0.cannotBeReached } }
        set { state.withLock { $0.cannotBeReached = newValue } }
    }

    public var asked: [[ProductID]] { state.withLock { $0.asked } }

    public func sells(_ ids: Int...) {
        stillSells = Set(ids.map(pid))
    }

    /// What it has, and how much of it. A shopper's two alert lists are told
    /// apart by exactly this.
    public var soldOut: Set<ProductID> {
        get { state.withLock { $0.soldOut } }
        set { state.withLock { $0.soldOut = newValue } }
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        state.withLock { state in
            state.asked.append(ids)
            guard !state.cannotBeReached else { return .failure(.unavailable) }
            return .success(
                ids.filter { state.stillSells.contains($0) }.map {
                    Product.fixture(
                        id: $0.rawValue,
                        availability: state.soldOut.contains($0) ? .outOfStock : .inStock(remaining: 10)
                    )
                }
            )
        }
    }
}
