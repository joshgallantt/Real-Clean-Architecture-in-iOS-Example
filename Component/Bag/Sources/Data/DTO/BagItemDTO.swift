import Foundation
import Bag
import Money
import Product

struct BagItemDTO: Codable, Sendable {
    let productId: Int
    let quantity: Int
    /// Whole minor units, the same way `Money` counts them, so a bag read back off disk
    /// totals to exactly what it totalled before it was written.
    let lastKnownPriceMinorUnits: Int
    let currencyCode: String
    let dateAdded: Date

    init(from item: BagItem) {
        self.productId = item.productId.rawValue
        self.quantity = item.quantity
        self.lastKnownPriceMinorUnits = item.lastKnownPrice.minorUnits
        self.currencyCode = item.lastKnownPrice.currency.code
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> BagItem {
        BagItem(
            productId: ProductID(rawValue: productId),
            quantity: quantity,
            lastKnownPrice: Money(
                minorUnits: lastKnownPriceMinorUnits,
                currency: Currency(code: currencyCode, minorUnitsPerMajor: 100)
            ),
            dateAdded: dateAdded
        )
    }
}
