import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the root, enforcing its own invariants on the
/// way in — each product once, newest first. Asking twice is one alert, because a shopper who taps
/// the bell again has not asked to be told twice.
///
/// It is the wishlist's twin in shape and not in meaning. A wishlist says "I want this"; a stock
/// alert says "tell me when you have this", which is a promise of a message to come. That promise
/// is the reason this is its own component: when telling somebody becomes a push rather than a
/// list, or when there is more to be told about than something coming back, only this changes.
///
/// Evans — Side-Effect-Free Functions.
public struct StockAlerts: Equatable, Sendable {
    public let items: [StockAlert]

    public init(items: [StockAlert] = []) {
        var seen: Set<ProductID> = []
        self.items = items
            .filter { seen.insert($0.productId).inserted }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    public var isEmpty: Bool { items.isEmpty }

    public var itemCount: Int { items.count }

    /// Whether the shopper has an alert on this product at all. The alert stays when the shop has
    /// some again — "tell me when this is back" is still true of a thing that could sell out once
    /// more. Only clearing the alert takes it off.
    public func contains(productId: ProductID) -> Bool {
        items.contains { $0.productId == productId }
    }

    public func adding(_ item: StockAlert) -> StockAlerts {
        guard !contains(productId: item.productId) else { return self }
        return StockAlerts(items: items + [item])
    }

    public func removing(productId: ProductID) -> StockAlerts {
        guard contains(productId: productId) else { return self }
        return StockAlerts(items: items.filter { $0.productId != productId })
    }
}
