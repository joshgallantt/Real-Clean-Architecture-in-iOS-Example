import Foundation
import Bag
import Money
import Product

/// Prices as amounts rather than raw numbers. There is no `Double.cents` helper any more,
/// because the arithmetic is exact and the assertions can just say what they mean.
func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func item(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}

// MARK: - What the shop says

func shopSells(_ id: Int, at price: Decimal, remaining: Int = 10) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(price), availability: .inStock(remaining: remaining))
}

func shopHasSoldOutOf(_ id: Int) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(1), availability: .outOfStock)
}

func shopHasDiscontinued(_ id: Int) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(1), availability: .discontinued)
}
