import Money
import Product

/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: each way the shop can
/// change its mind is a case, so a notice cannot be built that says two things at once or nothing
/// at all.
///
/// Fowler, *PoEAA* (2002) — Money: `priceMove` compares exact amounts, so a price that did not move
/// produces no notice. Float drift would make one.
public enum BagChange: Equatable, Sendable {
    case priceWentUp(productId: ProductID, from: Money, to: Money)
    case priceWentDown(productId: ProductID, from: Money, to: Money)

    case onlySomeLeft(productId: ProductID, available: Int)

    /// Two cases, not one with a reason attached, because a shopper reads them completely
    /// differently: one is worth waiting for and the other is not. Collapsing them would let a
    /// screen offer to tell somebody when a thing that is never coming back comes back.
    case outOfStock(productId: ProductID)
    case discontinued(productId: ProductID)

    public var productId: ProductID {
        switch self {
        case .priceWentUp(let id, _, _),
             .priceWentDown(let id, _, _),
             .onlySomeLeft(let id, _),
             .outOfStock(let id),
             .discontinued(let id):
            id
        }
    }

    var isAboutAProductStillInTheBag: Bool {
        switch self {
        case .priceWentUp, .priceWentDown, .onlySomeLeft: true
        case .outOfStock, .discontinued: false
        }
    }

    var priceLastSeen: Money? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .onlySomeLeft, .outOfStock, .discontinued: nil
        }
    }

    var isPriceMove: Bool {
        priceLastSeen != nil
    }

    static func priceMove(productId: ProductID, from: Money, to: Money) -> BagChange? {
        guard from != to else { return nil }
        return to > from
            ? .priceWentUp(productId: productId, from: from, to: to)
            : .priceWentDown(productId: productId, from: from, to: to)
    }
}
