import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the root, enforcing its own invariants on the
/// way in — each product once, newest first. Joining twice is one place on the list, because a
/// shopper who taps the bell again has not asked to be told twice.
///
/// It is the wishlist's twin in shape and not in meaning. A wishlist says "I want this"; a waitlist
/// says "tell me when you have this", which is a promise of a message to come. That promise is the
/// reason this is its own component: when telling somebody becomes a push rather than a list, only
/// this changes.
///
/// Evans — Side-Effect-Free Functions.
public struct Waitlist: Equatable, Sendable {
    public let items: [WaitlistItem]

    public init(items: [WaitlistItem] = []) {
        var seen: Set<ProductID> = []
        self.items = items
            .filter { seen.insert($0.productId).inserted }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    public var isEmpty: Bool { items.isEmpty }

    public var itemCount: Int { items.count }

    /// Whether the shopper is waiting on this product at all. It stays on the list when the shop has
    /// some again — "tell me when this is back" is still true of a thing that could sell out once
    /// more. Only leaving the list takes something off.
    public func contains(productId: ProductID) -> Bool {
        items.contains { $0.productId == productId }
    }

    public func adding(_ item: WaitlistItem) -> Waitlist {
        guard !contains(productId: item.productId) else { return self }
        return Waitlist(items: items + [item])
    }

    public func removing(productId: ProductID) -> Waitlist {
        guard contains(productId: productId) else { return self }
        return Waitlist(items: items.filter { $0.productId != productId })
    }
}
