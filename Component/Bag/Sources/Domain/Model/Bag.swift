import Foundation
import Money
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the aggregate root, and the only door in. Its
/// invariants are enforced by the initialiser rather than promised in prose — one line per product,
/// no line with none of it, newest first. A bag cannot be in those states because building one out
/// of them produces a bag that isn't.
///
/// Evans — Side-Effect-Free Functions: every change returns a new `Bag`, so the invariants are
/// re-established by the initialiser on every path rather than defended after the fact.
public struct Bag: Equatable, Sendable {
    public let items: [BagItem]

    public init(items: [BagItem] = []) {
        var order: [ProductID] = []
        var byProduct: [ProductID: BagItem] = [:]

        for item in items where item.quantity > 0 {
            if let existing = byProduct[item.productId] {
                byProduct[item.productId] = existing.withQuantity(existing.quantity + item.quantity)
            } else {
                byProduct[item.productId] = item
                order.append(item.productId)
            }
        }

        self.items = order
            .compactMap { byProduct[$0] }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    // MARK: - What the bag is worth

    /// Fowler, *PoEAA* (2002) — Money. Nothing at all when the bag is empty: there is no currency
    /// in an empty bag to name an amount in.
    public var total: Money? {
        items.map(\.lineTotal).total()
    }

    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public func holds(productId: ProductID) -> Bool {
        items.contains { $0.productId == productId }
    }

    public func quantity(of productId: ProductID) -> Int {
        items.first { $0.productId == productId }?.quantity ?? 0
    }

    // MARK: - How the bag changes

    public func adding(_ item: BagItem) -> Bag {
        guard let existing = items.first(where: { $0.productId == item.productId }) else {
            return Bag(items: items + [item])
        }
        return replacing(
            existing
                .withQuantity(existing.quantity + item.quantity)
                .withPrice(item.lastKnownPrice)
        )
    }

    public func removing(productId: ProductID) -> Bag {
        Bag(items: items.filter { $0.productId != productId })
    }

    public func changingQuantity(of productId: ProductID, to quantity: Int) -> Bag {
        guard quantity > 0 else { return removing(productId: productId) }
        guard let existing = items.first(where: { $0.productId == productId }) else { return self }
        return replacing(existing.withQuantity(quantity))
    }

    private func replacing(_ item: BagItem) -> Bag {
        Bag(items: items.map { $0.productId == item.productId ? item : $0 })
    }
}
