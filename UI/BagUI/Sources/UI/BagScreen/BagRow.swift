import Foundation
import Bag
import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a view model in the
/// literal sense — what the bag knows joined to what the catalog knows, shaped for one screen. A
/// headless bag has no use for it, which is why it is here and not in the domain.
struct BagRow: Identifiable, Equatable {
    let id: ProductID
    let quantity: Int
    let unitPrice: Money
    let lineTotal: Money
    let name: String?
    let imageURL: String?

    init(item: BagItem, name: String?, imageURL: String?) {
        self.id = item.id
        self.quantity = item.quantity
        self.unitPrice = item.lastKnownPrice
        self.lineTotal = item.lineTotal
        self.name = name
        self.imageURL = imageURL
    }
}
