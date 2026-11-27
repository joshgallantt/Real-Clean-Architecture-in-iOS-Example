import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: one thing the
/// shop changed about a bag since its shopper last saw it. Each way the shop can change its mind is
/// a case, so a change cannot be built that says two things at once or nothing at all.
///
/// Evans, Ch. 10 — Side-Effect-Free Functions: never stored. A change is the difference between the
/// bag as it was kept and the bag as the shop says it is now, so it is worked out from the two each
/// time — see `Bag.checked(against:asked:)` — and there is no second record to drift from the first.
public enum BagChange: Equatable, Hashable, Sendable {
    /// Kept apart from a fall: one is a price a shopper did not agree to and the other is good news.
    case priceWentUp(productId: ProductID, from: Money, to: Money)
    case priceWentDown(productId: ProductID, from: Money, to: Money)

    /// The shopper wanted more than the shop has, so the line holds what is left.
    case onlySomeLeft(productId: ProductID, available: Int)

    /// Gone for now, so no longer a line. The one change a shopper can wait out.
    case soldOut(productId: ProductID)

    public var productId: ProductID {
        switch self {
        case .priceWentUp(let id, _, _),
             .priceWentDown(let id, _, _),
             .onlySomeLeft(let id, _),
             .soldOut(let id):
            id
        }
    }
}
