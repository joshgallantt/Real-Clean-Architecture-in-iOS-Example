import Product
import StockAlert

/// Answers whatever it was told to, and counts how often it was asked.
@MainActor
public final class SpyGetStockAlertProductsUseCase: GetStockAlertProductsUseCase {
    public init() {}

    public var result: Result<[Product], StockAlertError> = .success([])
    public private(set) var callCount = 0

    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        callCount += 1
        return result
    }
}
