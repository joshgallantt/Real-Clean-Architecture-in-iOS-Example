import Foundation
import Bag

/// One line as the screen needs it: what the bag knows joined to what the catalog
/// knows. Purely a rendering concern — a headless bag has no use for it, which is why
/// it lives here and not in the domain.
///
/// `name` and `imageURL` are optional because the catalog may not have answered yet, or
/// at all. The row still renders, and it still costs what it costs.
struct BagRow: Identifiable, Equatable {
    let id: Int
    let quantity: Int
    let lastKnownPrice: Double
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

/// A line the shopper needs to be told about, with the change already put into words.
struct ChangedBagRow: Identifiable, Equatable {
    let id: Int
    let name: String?
    let imageURL: String?
    let summary: String

    init(change: BagChange, name: String?, imageURL: String?) {
        self.id = change.itemId
        self.name = name
        self.imageURL = imageURL
        self.summary = Self.summary(for: change)
    }

    private static func summary(for change: BagChange) -> String {
        switch change {
        case .priceWentUp(_, let from, let to):
            "Price went up from \(money(from)) to \(money(to))"
        case .priceWentDown(_, let from, let to):
            "Price dropped from \(money(from)) to \(money(to))"
        case .outOfStock:
            "Out of stock — we'll confirm at checkout"
        }
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
