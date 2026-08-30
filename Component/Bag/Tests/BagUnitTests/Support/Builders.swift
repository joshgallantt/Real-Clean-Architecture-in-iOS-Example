import MoneyTestSupport
import Foundation
import Money
import Product
import ProductTestSupport
@testable import Bag

// Builders, not a fixture: each call makes fresh data from the one or two
// values the test cares about, so no test is reading state another test owns.

func item(_ id: Int, quantity: Int = 1, at price: Decimal, added: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: added)
}
