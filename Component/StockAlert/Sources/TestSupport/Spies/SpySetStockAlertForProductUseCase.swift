import Product
import Session
import StockAlert

@MainActor
public final class SpySetStockAlertForProductUseCase: SetStockAlertForProductUseCase {
    public init() {}

    public var result: Result<Void, StockAlertError> = .success(())
    public var onSuccess: (Bool) -> Void = { _ in }
    public private(set) var calls: [(productId: ProductID, isOn: Bool)] = []

    public func callAsFunction(productId: ProductID, isOn: Bool) async -> Result<Void, StockAlertError> {
        calls.append((productId, isOn))
        await Task.yield()
        if case .success = result { onSuccess(isOn) }
        return result
    }
}
