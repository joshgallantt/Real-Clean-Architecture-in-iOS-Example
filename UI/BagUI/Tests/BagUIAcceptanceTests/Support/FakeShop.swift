import Combine
import Foundation
import Bag
import Money
import Product
import ProductTestSupport
@testable import BagUI

/// The app layer conforms `Navigator` to this. The bag screen only ever pushes product details, so
/// that is all the test needs to know about.
@MainActor
final class StubBagNavigation: BagNavigation {
    private(set) var openedProducts: [ProductID] = []

    nonisolated func openProductDetails(id: ProductID) {
        MainActor.assumeIsolated { openedProducts.append(id) }
    }
}

// MARK: - Fixtures

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func bagItem(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}
