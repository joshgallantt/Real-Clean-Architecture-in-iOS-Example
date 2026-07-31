import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: one word for the thing a
/// shopper is told. The screen shows notices, so the domain says `Notice` — this was `BagChange`
/// here and `Notice` there, in a bag where "change" already meant changing how many you want.
///
/// Evans, Ch. 9 — Making Implicit Concepts Explicit: each way the shop can change its mind is a
/// case, so a notice cannot be built that says two things at once or nothing at all.
public enum Notice: Equatable, Sendable {
    case outOfStock(productId: ProductID)
    case onlySomeLeft(productId: ProductID, available: Int)
    case priceWentUp(productId: ProductID, from: Money, to: Money)
    case priceWentDown(productId: ProductID, from: Money, to: Money)

    /// Evans, Ch. 9 — Making Implicit Concepts Explicit: which of the four a notice is, named apart
    /// from what it carries. Which kind something was used to be recorded twice over — as `if case`
    /// filters on the collection, and again as a second enum in the bag screen — so a new notice
    /// meant three lists to find and agree.
    public enum Kind: Equatable, Sendable {
        case outOfStock
        case onlySomeLeft

        /// Kept apart from a rise, because only one of them asks anything of a shopper. A single
        /// "price moved" would put good news and a decision in the same list.
        case priceWentUp
        case priceWentDown
    }

    public var kind: Kind {
        switch self {
        case .outOfStock: .outOfStock
        case .onlySomeLeft: .onlySomeLeft
        case .priceWentUp: .priceWentUp
        case .priceWentDown: .priceWentDown
        }
    }

    public var productId: ProductID {
        switch self {
        case .outOfStock(let id),
             .onlySomeLeft(let id, _),
             .priceWentUp(let id, _, _),
             .priceWentDown(let id, _, _):
            id
        }
    }

    /// Whether this is news about a line that has *left* the bag. One kind goes and three stay, and
    /// which side a notice falls on is what decides when it stops being worth telling.
    var isAboutSomethingGone: Bool {
        switch kind {
        case .outOfStock: true
        case .priceWentUp, .priceWentDown, .onlySomeLeft: false
        }
    }

    /// The price the shopper was last shown, which is not always the price on the line: a notice
    /// still waiting means they have not seen the line's price yet.
    var priceLastSeen: Money? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .onlySomeLeft, .outOfStock: nil
        }
    }

    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: exact amounts, so a price that did not move produces
    /// no notice at all. Float drift would manufacture one.
    static func priceMove(productId: ProductID, from: Money, to: Money) -> Notice? {
        guard from != to else { return nil }
        return to > from
            ? .priceWentUp(productId: productId, from: from, to: to)
            : .priceWentDown(productId: productId, from: from, to: to)
    }
}
