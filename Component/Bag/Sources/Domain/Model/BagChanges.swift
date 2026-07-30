import Money
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: a separate root, not part of the bag. It
/// changes for different reasons and at different times — the bag when the shopper shops, this when
/// the shop changes its mind — and one entry is about a product that has *left* the bag, which the
/// bag could not hold without referring outside itself.
public struct BagChanges: Equatable, Sendable {
    public let all: [BagChange]

    public init(_ all: [BagChange] = []) {
        self.all = all
    }

    public var isEmpty: Bool { all.isEmpty }

    /// Everything that has left the bag, whichever way it went.
    public var gone: [BagChange] { all.filter { !$0.isAboutAProductStillInTheBag } }

    /// The shop has run out and expects it back — worth waiting for.
    public var outOfStock: [BagChange] {
        all.filter { if case .outOfStock = $0 { true } else { false } }
    }

    /// The shop has stopped selling it — nothing to wait for.
    public var discontinued: [BagChange] {
        all.filter { if case .discontinued = $0 { true } else { false } }
    }

    public var priceMoves: [BagChange] { all.filter(\.isPriceMove) }

    /// Told apart because a shopper does not read them the same way. One is a thing to decide
    /// about and the other is not, and a section that mixed them would ask for a decision about
    /// good news.
    public var priceIncreases: [BagChange] {
        all.filter { if case .priceWentUp = $0 { true } else { false } }
    }

    public var priceDecreases: [BagChange] {
        all.filter { if case .priceWentDown = $0 { true } else { false } }
    }

    public var shortages: [BagChange] {
        all.filter { if case .onlySomeLeft = $0 { true } else { false } }
    }

    public func about(productId: ProductID) -> [BagChange] {
        all.filter { $0.productId == productId }
    }

    public func priceLastSeen(forProductId productId: ProductID) -> Money? {
        all.first { $0.productId == productId && $0.isPriceMove }?.priceLastSeen
    }

    public func acknowledging(productId: ProductID) -> BagChanges {
        BagChanges(all.filter { $0.productId != productId })
    }
}
