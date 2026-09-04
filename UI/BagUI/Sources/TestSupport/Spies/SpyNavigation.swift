import Bag
import Money
import Product
import ProductTestSupport
@testable import BagUI

@MainActor
final class SpyNavigation: BagNavigation {
    private(set) var openedProducts: [Product] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product) }
    }
}
