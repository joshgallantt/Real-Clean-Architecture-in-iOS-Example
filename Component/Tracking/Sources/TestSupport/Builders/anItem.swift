import Foundation
import Money
import Tracking

/// A product item for a test that cares that something was tracked, not what. Named the way the
/// catalog fixture names its products, so a log line reads the same either way.
public func anItem(_ id: Int, price: Decimal, quantity: Int) -> TrackedItem {
    .product(
        id: String(id),
        name: "Product \(id)",
        category: "beauty",
        price: Money(amount: price, currency: .usd),
        quantity: quantity
    )
}
