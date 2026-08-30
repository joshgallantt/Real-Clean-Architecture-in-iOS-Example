import MoneyTestSupport
import Foundation
import Bag
import Money
import Product
import ProductTestSupport
@testable import BagUI

func bagItem(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}
