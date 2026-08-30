import Bag
import Money
import Product
import ProductTestSupport
@testable import BagUI

@MainActor
final class SpyNavigation: BagNavigation {
    private(set) var openedProducts: [ProductID] = []

    nonisolated func openProductDetails(id: ProductID) {
        MainActor.assumeIsolated { openedProducts.append(id) }
    }
}
