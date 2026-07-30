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

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the notice already
/// put into words, so the view holds no wording decisions.
///
/// Most notices have no words of their own. What happened to a row is what its section is for, and
/// saying "out of stock" down a column of out-of-stock things is a sentence a shopper has to read
/// past on every line to reach the one thing that differs — the product. So `detail` is filled in
/// only where a row knows something its heading cannot: how many are left.
///
/// A price move is the other half of that. It is worth seeing rather than reading — the old amount
/// struck through, the new one coloured by which way it went — and a view cannot strike through
/// half of a finished sentence. So `priceMove` hands over the two amounts and the direction. The
/// words come from here and the emphasis from the view, which is the line between the two rather
/// than a leak across it.
struct ChangedBagRow: Identifiable, Equatable {
    struct PriceMove: Equatable {
        let was: String
        let now: String
        let isCheaper: Bool
    }

    let id: ProductID
    let name: String?
    let imageURL: String?
    let detail: String?
    let priceMove: PriceMove?

    init(change: BagChange, name: String?, imageURL: String?) {
        self.id = change.productId
        self.name = name
        self.imageURL = imageURL
        self.detail = Self.detail(for: change)
        self.priceMove = Self.priceMove(for: change)
    }

    /// How many are left is the one thing a section heading cannot say, because it differs by row.
    /// Everything else about these notices is said once, above them.
    private static func detail(for change: BagChange) -> String? {
        switch change {
        case .onlySomeLeft(_, let available):
            available == 1 ? "Only 1 left" : "Only \(available) left"
        case .priceWentUp, .priceWentDown, .outOfStock, .discontinued:
            nil
        }
    }

    private static func priceMove(for change: BagChange) -> PriceMove? {
        switch change {
        case .priceWentUp(_, let from, let to):
            PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: false)
        case .priceWentDown(_, let from, let to):
            PriceMove(was: from.formatted(), now: to.formatted(), isCheaper: true)
        case .onlySomeLeft, .outOfStock, .discontinued:
            nil
        }
    }
}
