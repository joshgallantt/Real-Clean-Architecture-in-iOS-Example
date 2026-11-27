import Product
@testable import WishlistUI

@MainActor
final class SpyWishlistNavigation: WishlistNavigation {
    private(set) var openedProducts: [Product] = []

    nonisolated func openProductDetails(product: Product) {
        MainActor.assumeIsolated { openedProducts.append(product) }
    }

    nonisolated func openAllFaves() {}
}
