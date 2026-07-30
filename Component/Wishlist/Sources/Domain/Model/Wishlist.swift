import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the root, enforcing its own invariants on the
/// way in — each product once, newest first. Unlike a bag it keeps no prices: a shopper saves
/// something precisely to watch what happens to it, so what it costs is the catalog's to answer,
/// freshly.
///
/// Evans — Side-Effect-Free Functions.
public struct Wishlist: Equatable, Sendable {
    public let items: [WishlistItem]

    public init(items: [WishlistItem] = []) {
        var seen: Set<ProductID> = []
        self.items = items
            .filter { seen.insert($0.productId).inserted }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    public var isEmpty: Bool { items.isEmpty }

    public var itemCount: Int { items.count }

    public func contains(productId: ProductID) -> Bool {
        items.contains { $0.productId == productId }
    }

    public func adding(_ item: WishlistItem) -> Wishlist {
        guard !contains(productId: item.productId) else { return self }
        return Wishlist(items: items + [item])
    }

    public func removing(productId: ProductID) -> Wishlist {
        guard contains(productId: productId) else { return self }
        return Wishlist(items: items.filter { $0.productId != productId })
    }
}
