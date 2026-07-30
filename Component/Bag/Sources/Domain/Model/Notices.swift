import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a separate root, not part of the bag.
/// It changes for different reasons and at different times — the bag when the shopper shops, this
/// when the shop changes its mind — and one entry is about a product that has *left* the bag, which
/// the bag could not hold without referring outside itself.
public struct Notices: Equatable, Sendable {
    public let all: [Notice]

    public init(_ all: [Notice] = []) {
        self.all = all
    }

    public var isEmpty: Bool { all.isEmpty }

    /// Evans, Ch. 10 — Conceptual Contours: one way to ask for some of them, whatever is being
    /// asked for. This was seven properties, each filtering `all` for one case, and a screen that
    /// could only group notices the ways the domain had happened to name.
    public func of(_ kinds: Notice.Kind...) -> [Notice] {
        all.filter { kinds.contains($0.kind) }
    }

    /// Everything that has left the bag, whichever of the two ways it went.
    public var gone: [Notice] { all.filter(\.isAboutSomethingGone) }

    public func about(_ productId: ProductID) -> [Notice] {
        all.filter { $0.productId == productId }
    }

    /// The price this shopper was last shown for a product, while they are still owed word about it.
    public func priceLastSeen(forProductId productId: ProductID) -> Money? {
        about(productId).lazy.compactMap(\.priceLastSeen).first
    }

    /// Evans, Ch. 10 — Side-Effect-Free Functions: acknowledging is by product, not by notice —
    /// "Okay" has always meant "I have seen what happened to this one".
    public func acknowledging(_ productId: ProductID) -> Notices {
        Notices(all.filter { $0.productId != productId })
    }
}
