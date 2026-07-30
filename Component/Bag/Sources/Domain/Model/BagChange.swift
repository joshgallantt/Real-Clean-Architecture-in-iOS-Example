import Money
import Product

/// Something the shop did to one of the shopper's choices while they were away, still
/// waiting to be mentioned to them.
public enum BagChange: Equatable, Sendable {
    /// `from` is the price the shopper last saw and dismissed, not the price at the
    /// previous lookup — so a price that moved three times while they were away reads as
    /// one move, from what they knew to what is true now.
    case priceWentUp(productId: ProductID, from: Money, to: Money)
    case priceWentDown(productId: ProductID, from: Money, to: Money)

    /// The shop cannot supply as many as the shopper asked for, so the line has been cut
    /// down to what it can. Still in the bag, just fewer.
    case onlySomeLeft(productId: ProductID, available: Int)

    /// The shop cannot supply it, so it has left the bag. This is how the shopper finds
    /// out, rather than noticing a shorter list.
    case noLongerAvailable(productId: ProductID)

    public var productId: ProductID {
        switch self {
        case .priceWentUp(let id, _, _),
             .priceWentDown(let id, _, _),
             .onlySomeLeft(let id, _),
             .noLongerAvailable(let id):
            id
        }
    }

    /// Whether this is news about something still in the bag. A price and a shortage are;
    /// a product that has gone is not.
    var isAboutAProductStillInTheBag: Bool {
        switch self {
        case .priceWentUp, .priceWentDown, .onlySomeLeft: true
        case .noLongerAvailable: false
        }
    }

    /// The price this change started from, so a later move can be folded into it rather
    /// than stacked on top. Only a price move has one.
    var priceLastSeen: Money? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .onlySomeLeft, .noLongerAvailable: nil
        }
    }

    var isPriceMove: Bool {
        priceLastSeen != nil
    }

    /// A price move, or nothing at all if the price did not actually move. Exact, because
    /// `Money` counts whole minor units — two prices that look the same are the same.
    static func priceMove(productId: ProductID, from: Money, to: Money) -> BagChange? {
        guard from != to else { return nil }
        return to > from
            ? .priceWentUp(productId: productId, from: from, to: to)
            : .priceWentDown(productId: productId, from: from, to: to)
    }
}
