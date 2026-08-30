import Money
import Order
import Product

@MainActor
public final class StubPlaceOrder: PlaceOrderUseCase {
    public init() {}

    public var result: Result<Order, OrderError> = .success(.fixture())
    public private(set) var calls: [[OrderLine]] = []

    private var holdsTheNextOrderOpen = false
    private var releaseTheHeldOrder: CheckedContinuation<Void, Never>?
    private var announceHolding: CheckedContinuation<Void, Never>?

    public var isHoldingAnOrderOpen: Bool { releaseTheHeldOrder != nil }

    public func holdTheNextOrderOpen() {
        holdsTheNextOrderOpen = true
    }

    public func finishTheHeldOrder() {
        holdsTheNextOrderOpen = false
        releaseTheHeldOrder?.resume()
        releaseTheHeldOrder = nil
    }

    /// Returns once the order is open and being held, so a test can look at the
    /// screen mid-flight. Awaiting the work itself would deadlock — it does not
    /// finish until `finishTheHeldOrder()` — and yielding until a flag flips is a
    /// guess about scheduling rather than a wait.
    public func untilHolding() async {
        guard !isHoldingAnOrderOpen else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            announceHolding = continuation
        }
    }

    public func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError> {
        calls.append(lines)

        if holdsTheNextOrderOpen {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                releaseTheHeldOrder = continuation
                announceHolding?.resume()
                announceHolding = nil
            }
        }

        return result
    }
}
