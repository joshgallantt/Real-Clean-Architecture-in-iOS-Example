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

    public var isHoldingAnOrderOpen: Bool { releaseTheHeldOrder != nil }

    public func holdTheNextOrderOpen() {
        holdsTheNextOrderOpen = true
    }

    public func finishTheHeldOrder() {
        holdsTheNextOrderOpen = false
        releaseTheHeldOrder?.resume()
        releaseTheHeldOrder = nil
    }

    public func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError> {
        calls.append(lines)

        if holdsTheNextOrderOpen {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                releaseTheHeldOrder = continuation
            }
        }

        return result
    }
}
