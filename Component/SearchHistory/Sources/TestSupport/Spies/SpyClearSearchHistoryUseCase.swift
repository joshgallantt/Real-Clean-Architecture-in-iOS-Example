import Product
import SearchHistory

@MainActor
public final class SpyClearSearchHistoryUseCase: ClearSearchHistoryUseCase {
    public init() {}

    public private(set) var callCount = 0

    public func callAsFunction() {
        callCount += 1
    }
}
