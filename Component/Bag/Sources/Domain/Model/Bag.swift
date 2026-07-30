import Foundation
import Money
import Product

/// The shopper's bag: what is in it, what it is worth, and every rule about how it
/// changes.
///
/// Everything inside the bag changes through the bag, and the door is the initialiser
/// rather than a promise about how callers behave. Two lines for the same product, a line
/// with none of it, an order that isn't newest first — a bag cannot be in those states,
/// because building one out of them produces a bag that isn't. Anything handed in, including
/// a file written by an older build, is put right on the way in rather than trusted.
///
/// The total is computed from the last prices the shopper was shown, so it is there on a
/// dead connection. It is the best available answer, not a promise.
///
/// What the shop has changed since they last looked is `BagChanges`, kept separately:
/// that is a list of things to tell them, not a list of things they are buying.
public struct Bag: Equatable, Sendable {
    public let items: [BagItem]

    /// - Lines with none of something are not lines, so they are dropped.
    /// - Two lines for one product are one line: the counts add up, and the earlier line's
    ///   price and date stand, because that is when the shopper put it in the bag.
    /// - Newest first is the bag's own order, so it is established here rather than trusted
    ///   from whatever handed the lines over.
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

    /// Nothing at all when the bag is empty: an empty bag is not worth zero of any
    /// particular currency, because there is no currency in it to name.
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

    /// Choosing something already in the bag takes another of it. There is one line per
    /// product, and it carries the price the shopper was shown most recently — taking a
    /// second one at today's price does not leave the first sitting at last week's.
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

    /// Asking for none of something is how a shopper puts it back, and asking about
    /// something that isn't in the bag changes nothing.
    public func changingQuantity(of productId: ProductID, to quantity: Int) -> Bag {
        guard quantity > 0 else { return removing(productId: productId) }
        guard let existing = items.first(where: { $0.productId == productId }) else { return self }
        return replacing(existing.withQuantity(quantity))
    }

    private func replacing(_ item: BagItem) -> Bag {
        Bag(items: items.map { $0.productId == item.productId ? item : $0 })
    }
}
