import Foundation
import Money
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: the aggregate root, and the only door in. Its
/// invariants are enforced by the initialiser rather than promised in prose — one line per product,
/// no line with none of it, newest first. A bag cannot be in those states because building one out
/// of them produces a bag that isn't.
///
/// Evans, Ch. 10 — Side-Effect-Free Functions: every change returns a new `Bag`, so the invariants are
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

    /// Fowler, *PoEAA* (2002), Ch. 18 — Money. Nothing at all when the bag is empty: there is no currency
    /// in an empty bag to name an amount in.
    public var total: Money? {
        Money.total(of: items.map(\.lineTotal))
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

    /// The bag with this line as given: this many, at this price. None of something takes it out.
    /// A line that was already there keeps its place — when it was first added does not change
    /// because how many did.
    public func setting(_ item: BagItem) -> Bag {
        guard item.quantity > 0 else { return removing(productId: item.productId) }
        guard let existing = items.first(where: { $0.productId == item.productId }) else {
            return Bag(items: items + [item])
        }
        return replacing(existing.withQuantity(item.quantity).withPrice(item.lastKnownPrice))
    }

    public func removing(productId: ProductID) -> Bag {
        Bag(items: items.filter { $0.productId != productId })
    }

    private func replacing(_ item: BagItem) -> Bag {
        Bag(items: items.map { $0.productId == item.productId ? item : $0 })
    }

    /// The lines to set, one at a time, for this bag to become that one: none of each line that is
    /// not in it, and each line that differs as it is there. It is how a bag is kept as its shopper
    /// last saw it without a second way of writing one — and a bag that is already that bag has
    /// nothing to set.
    public func lines(toBecome other: Bag) -> [BagItem] {
        let leaving = items
            .filter { !other.holds(productId: $0.productId) }
            .map { $0.withQuantity(0) }

        return leaving + other.items.filter { !items.contains($0) }
    }

    // MARK: - What the shop says about it

    /// Evans, Ch. 10 — Side-Effect-Free Functions: this bag held against what the shop says now, a
    /// line at a time. Every line either stays — at whatever the shop now charges, and never for
    /// more than the shop can supply — or it is not a line any more. Nothing is saved and nothing
    /// is remembered: asked the same question about the same bag, it gives the same answer.
    ///
    /// `asked` is what tells a shop that said nothing about a product from a shop that was never
    /// asked about it. Asking about nothing is therefore how a shop that could not be reached is
    /// said: every line is left as it was and nothing has changed.
    public func checked(against products: [Product], asked: Set<ProductID>) -> CheckedBag {
        let shop = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        var kept: [BagItem] = []
        var changes: [BagChange] = []

        for line in items {
            guard let says = shop[line.productId] else {
                /// Not asked about, so nothing has been learned and the line stays as it was. Asked
                /// about and not described: the shop has stopped selling it, so the line goes and
                /// nothing is said. There is nothing a shopper can do with the news — it cannot be
                /// waited for, bought or put back.
                if !asked.contains(line.productId) { kept.append(line) }
                continue
            }

            guard says.availability.isAvailable else {
                /// What its price did on the way out is not worth saying: it cannot be bought at
                /// either.
                changes.append(.soldOut(productId: line.productId))
                continue
            }

            changes.append(contentsOf: line.changes(nowThatTheShopSays: says))
            kept.append(line.matching(says))
        }

        return CheckedBag(bag: Bag(items: kept), changes: changes, products: products, asked: asked)
    }
}
