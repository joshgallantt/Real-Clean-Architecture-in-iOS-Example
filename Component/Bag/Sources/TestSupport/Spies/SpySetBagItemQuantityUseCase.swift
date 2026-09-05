import Bag
import Product
import ProductTestSupport

@MainActor
public final class SpySetBagItemQuantityUseCase: SetBagItemQuantityUseCase {
    public private(set) var calls: [(productId: ProductID, quantity: Int)] = []

    public init() {}

    public func callAsFunction(productId: ProductID, to quantity: Int) {
        calls.append((productId, quantity))
    }
}
