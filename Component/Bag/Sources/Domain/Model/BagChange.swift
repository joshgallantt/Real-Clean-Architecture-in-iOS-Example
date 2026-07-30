/// Something the shop did to one of the shopper's choices while they were away, still
/// waiting to be mentioned to them.
public enum BagChange: Equatable, Sendable {
    /// `from` is the price the shopper last saw and dismissed, not the price at the
    /// previous lookup — so a price that moved three times while they were away reads as
    /// one move, from what they knew to what is true now.
    case priceWentUp(productId: Int, from: Double, to: Double)
    case priceWentDown(productId: Int, from: Double, to: Double)

    /// The shop cannot supply it, so it has left the bag. This is how the shopper finds
    /// out, rather than noticing a shorter list.
    case noLongerAvailable(productId: Int)

    public var productId: Int {
        switch self {
        case .priceWentUp(let id, _, _), .priceWentDown(let id, _, _), .noLongerAvailable(let id):
            id
        }
    }

    /// Whether this is news about something still in the bag. A price is; a product that
    /// has gone is not.
    var isAboutAProductStillInTheBag: Bool {
        switch self {
        case .priceWentUp, .priceWentDown: true
        case .noLongerAvailable: false
        }
    }

    /// The price this change started from, so a later move can be folded into it rather
    /// than stacked on top.
    var priceLastSeen: Double? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .noLongerAvailable: nil
        }
    }

    /// A price move, or nothing at all if the price did not actually move.
    static func priceMove(productId: Int, from: Double, to: Double) -> BagChange? {
        guard from != to else { return nil }
        return to > from
            ? .priceWentUp(productId: productId, from: from, to: to)
            : .priceWentDown(productId: productId, from: from, to: to)
    }
}
