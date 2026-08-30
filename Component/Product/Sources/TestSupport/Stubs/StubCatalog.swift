import Money
import Product
import Synchronization

/// A shop with stock, which can also be made unreachable.
///
/// The merge of two: Bag's copy could refuse to answer and StockAlert's could
/// not, and they were otherwise the same character for character.
///
/// State lives in a `Mutex` rather than behind an `NSLock`, so the type is
/// `Sendable` because the compiler can see that it is. `@unchecked Sendable` is
/// a promise the compiler takes on trust and cannot check, which is worth
/// making where there is no alternative and worth removing where there is.
public final class StubCatalog: LookUpProductsUseCase {
    private struct State {
        var stock: [OnTheShelf] = []
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

    public var asked: [[ProductID]] { state.withLock { $0.asked } }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        state.withLock { state in
            state.asked.append(ids)
            guard !state.cannotBeReached else { return .failure(.unavailable) }
            let wanted = Set(ids)
            return .success(state.stock.filter { wanted.contains($0.id) }.map(\.product))
        }
    }
}
