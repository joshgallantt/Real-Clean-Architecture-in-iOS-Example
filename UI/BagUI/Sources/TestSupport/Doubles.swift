// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import Combine
import Foundation
import Bag
import Money
import Product
@testable import BagUI

@MainActor
final class SpyNavigation: BagNavigation {
    private(set) var openedProducts: [ProductID] = []

    nonisolated func openProductDetails(id: ProductID) {
        MainActor.assumeIsolated { openedProducts.append(id) }
    }
}

@MainActor
func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func bagItem(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}

extension Product {
    static func fixture(
        id: Int,
        price: Decimal = 9.99,
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: usd(price),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
