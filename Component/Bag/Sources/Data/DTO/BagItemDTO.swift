import Foundation
import Bag
import Money
import Product

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
struct BagItemDTO: Codable, Sendable {
    let productId: Int
    let quantity: Int
    /// Fowler, *PoEAA* (2002) — Money: stored as whole minor units, so a bag read back off disk
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
