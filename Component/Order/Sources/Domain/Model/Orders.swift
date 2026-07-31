/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: the root of what a shopper has bought,
/// enforcing its own invariants on the way in — one entry per order, newest first. Placing the same
/// order twice is one order, because a shopper who taps Buy Now twice on a slow connection has not
/// bought two of them.
///
/// Evans, Ch. 10 — Side-Effect-Free Functions: adding returns a new `Orders`, so the invariants are
/// re-established by the initialiser on every path rather than defended after the fact.
public struct Orders: Equatable, Sendable {
    public let all: [Order]

    public init(_ all: [Order] = []) {
        var seen: Set<OrderID> = []
        self.all = all
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.placedAt > $1.placedAt }
    }

    public var isEmpty: Bool { all.isEmpty }

    public var count: Int { all.count }

    public var mostRecent: Order? { all.first }

    public func adding(_ order: Order) -> Orders {
        Orders(all + [order])
    }
}
