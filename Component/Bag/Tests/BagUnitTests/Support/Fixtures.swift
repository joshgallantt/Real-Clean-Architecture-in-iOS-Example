import Foundation
import Money
import Product
@testable import Bag

func pid(_ value: Int) -> ProductID { ProductID(rawValue: value) }

func usd(_ amount: Decimal) -> Money { Money(amount: amount, currency: .usd) }

func item(_ id: Int, quantity: Int = 1, at price: Decimal, added: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: added)
}
