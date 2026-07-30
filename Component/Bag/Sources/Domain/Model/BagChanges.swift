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

    public var noLongerAvailable: [BagChange] { all.filter { !$0.isAboutAProductStillInTheBag } }

    public var priceMoves: [BagChange] { all.filter(\.isPriceMove) }

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
