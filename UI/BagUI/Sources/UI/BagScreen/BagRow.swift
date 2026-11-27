import Foundation
import Bag
import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a view model in the
/// literal sense — what the bag knows joined to what the catalog knows, shaped for one screen. A
/// headless bag has no use for it, which is why it is here and not in the domain.
///
/// The product itself, not the two fields the row happens to draw. A copy of a product's name and
/// picture is a second product model that drifts from the first; the row holds the entity and the
/// view reads what it needs. `nil` until the shop has answered about it, which the view draws as a
/// placeholder.
struct BagRow: Identifiable, Equatable {
    let id: ProductID
    let quantity: Int
    let unitPrice: Money
    let lineTotal: Money
    let product: Product?

    init(item: BagItem, product: Product?) {
        self.id = item.id
        self.quantity = item.quantity
        self.unitPrice = item.lastKnownPrice
        self.lineTotal = item.lineTotal
        self.product = product
    }
}
