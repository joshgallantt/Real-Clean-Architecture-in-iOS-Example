/// Something that happened to a line while the shopper was away, still waiting to be
/// mentioned to them.
///
/// Nothing here takes anything out of the bag. The shopper put it there; whether to
/// wait for it, or give up on it, is theirs to decide.
public enum BagChange: Equatable, Sendable {
    /// `from` is the price the shopper last saw and dismissed, not the price at the
    /// previous lookup — so a price that moved three times while they were away reads
    /// as one move, from what they knew to what is true now.
    case priceWentUp(itemId: Int, from: Double, to: Double)
    case priceWentDown(itemId: Int, from: Double, to: Double)
    case outOfStock(itemId: Int)

    public var itemId: Int {
        switch self {
        case .priceWentUp(let id, _, _), .priceWentDown(let id, _, _), .outOfStock(let id):
            id
        }
    }

    public var isPriceChange: Bool {
        switch self {
        case .priceWentUp, .priceWentDown: true
        case .outOfStock: false
        }
    }

    /// The price this change started from, so a later move can be folded into it.
    var priceLastSeen: Double? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .outOfStock: nil
        }
    }

    static func price(itemId: Int, from: Double, to: Double) -> BagChange? {
        guard from != to else { return nil }
        return to > from
            ? .priceWentUp(itemId: itemId, from: from, to: to)
            : .priceWentDown(itemId: itemId, from: from, to: to)
    }
}
