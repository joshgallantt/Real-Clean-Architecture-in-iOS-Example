import Product
import StockAlert

/// `onSuccess` is how a test makes a product with an alert start reading as having one. The real use
/// case writes through a repository that publishes what it kept, so anything observing it has heard
/// before the call returns. The yield is the round trip: without a suspension here every call would
/// finish before the next one could start, and no ordering would ever be at stake.
@MainActor
public final class SpySetProductStockAlertUseCase: SetProductStockAlertUseCase {
    public init() {}

    public var result: Result<Void, StockAlertError> = .success(())
    public var onSuccess: (Bool) -> Void = { _ in }
    public private(set) var calls: [(productId: ProductID, isOn: Bool)] = []

    public func callAsFunction(
        productId: ProductID,
        isOn: Bool
    ) async -> Result<Void, StockAlertError> {
        calls.append((productId, isOn))
        await Task.yield()
        if case .success = result { onSuccess(isOn) }
        return result
    }
}
