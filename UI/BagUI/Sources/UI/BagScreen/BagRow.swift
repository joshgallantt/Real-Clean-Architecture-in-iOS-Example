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
/// It does hold styling decisions, and `priceMove` is what lets it. A price move is worth seeing
/// rather than reading — the old amount struck through, the new one coloured by which way it went —
/// and a view cannot strike through half of a finished sentence. The words come from here and the
/// emphasis from the view, which is the line between the two rather than a leak across it.
struct ChangedBagRow: Identifiable, Equatable {
    struct PriceMove: Equatable {
        let was: String
        let now: String
        let isCheaper: Bool
    }

    let id: ProductID
    let name: String?
    let imageURL: String?
    let summary: String
    let priceMove: PriceMove?

    init(change: BagChange, name: String?, imageURL: String?) {
        self.id = change.productId
        self.name = name
        self.imageURL = imageURL
        self.summary = Self.summary(for: change)
        self.priceMove = Self.priceMove(for: change)
    }

    private static func summary(for change: BagChange) -> String {
        switch change {
        case .priceWentUp:
            "The price went up while this was in your bag"
        case .priceWentDown:
            "Good news — this got cheaper"
        case .onlySomeLeft(_, let available):
            available == 1
                ? "Only 1 left, so we've made it 1"
                : "Only \(available) left, so we've made it \(available)"
        case .outOfStock:
            "Out of stock — we'll have it back"
        case .discontinued:
            "The shop has stopped selling this"
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
