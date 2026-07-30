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
    let lastKnownPrice: Money
    let name: String?
    let imageURL: String?

    init(item: BagItem, name: String?, imageURL: String?) {
        self.id = item.id
        self.quantity = item.quantity
        self.lastKnownPrice = item.lastKnownPrice
        self.name = name
        self.imageURL = imageURL
    }
}

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the notice already
/// put into words, so the view holds no formatting decisions.
struct ChangedBagRow: Identifiable, Equatable {
    let id: ProductID
    let name: String?
    let imageURL: String?
    let summary: String

    init(change: BagChange, name: String?, imageURL: String?) {
        self.id = change.productId
        self.name = name
        self.imageURL = imageURL
        self.summary = Self.summary(for: change)
    }

    private static func summary(for change: BagChange) -> String {
        switch change {
        case .priceWentUp(_, let from, let to):
            "Price went up from \(from.formatted()) to \(to.formatted())"
        case .priceWentDown(_, let from, let to):
            "Price dropped from \(from.formatted()) to \(to.formatted())"
        case .onlySomeLeft(_, let available):
            available == 1
                ? "Only 1 left — we updated your bag"
                : "Only \(available) left — we updated your bag"
        case .outOfStock:
            "Out of stock — we'll have it back"
        case .discontinued:
            "No longer sold"
        }
    }
}
