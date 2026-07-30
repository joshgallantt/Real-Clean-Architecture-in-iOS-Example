/// Whether the shop can supply a product, and what it will say about it if it cannot.
///
/// One thing, not two. Held as a count plus a will-it-come-back flag, the flag is only
/// meaningful when the count is zero, and every caller has to know that to read either —
/// so callers end up rebuilding these three cases from two fields, each in their own way.
/// Here the states are the states, and an impossible combination cannot be written down.
public enum Availability: Equatable, Hashable, Sendable {
    case inStock(remaining: Int)

    /// The shop expects to have it again.
    case outOfStock

    /// The shop is not selling it any more.
    case discontinued

    /// Derived from how many there are rather than from which case this is, because
    /// `.inStock(remaining: 0)` can be written down and cannot be supplied. Anything that
    /// can supply none of itself is not available, whatever it calls itself.
    public var isAvailable: Bool {
        remaining > 0
    }

    /// How many the shop can supply, which is none unless it is in stock.
    public var remaining: Int {
        if case .inStock(let remaining) = self { return remaining }
        return 0
    }
}
