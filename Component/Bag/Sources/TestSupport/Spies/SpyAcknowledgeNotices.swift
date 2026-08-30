import Bag
import Product
import ProductTestSupport

@MainActor
public final class SpyAcknowledgeNotices: AcknowledgeNoticesUseCase {
    public private(set) var acknowledged: [ProductID] = []

    public init() {}

    public func callAsFunction(aboutProductId productId: ProductID) {
        acknowledged.append(productId)
    }
}
