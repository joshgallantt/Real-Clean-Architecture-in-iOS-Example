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

    var isAboutAProductStillInTheBag: Bool {
        switch self {
        case .priceWentUp, .priceWentDown, .onlySomeLeft: true
        case .noLongerAvailable: false
        }
    }

    var priceLastSeen: Money? {
        switch self {
        case .priceWentUp(_, let from, _), .priceWentDown(_, let from, _): from
        case .onlySomeLeft, .noLongerAvailable: nil
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
