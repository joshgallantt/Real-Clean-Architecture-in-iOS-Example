import Bag
import Foundation
import Product
import ProductTestSupport

@MainActor
public final class SpyBringBagUpToDateUseCase: BringBagUpToDateUseCase {
    public var products: [Product] = []
    public private(set) var callCount = 0

    public init() {}

    public func callAsFunction() async -> [Product] {
        callCount += 1
        return products
    }
}
