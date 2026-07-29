import Foundation

/// The shopper's bag: what is in it, what it is worth, and every rule about how it
/// changes.
///
/// Everything inside the bag changes through the bag. A caller that reached in to
/// rearrange the lines itself could put the bag into a state the bag would not allow —
/// two lines for the same product, a line with none of it, an order that isn't newest
/// first — so the only way in is through these.
///
/// The total is computed from the last prices the shopper was shown, so it is there on a
/// dead connection. It is the best available answer, not a promise.
///
/// What the shop has changed since they last looked is `BagChanges`, kept separately:
/// that is a list of things to tell them, not a list of things they are buying.
public struct Bag: Equatable, Sendable {
    public let items: [BagItem]

    /// Newest first is the bag's own order, so it is established here rather than
    /// trusted from whatever handed the lines over.
    public init(items: [BagItem] = []) {
        self.items = items.sorted { $0.dateAdded > $1.dateAdded }
    }

    // MARK: - What the bag is worth

    public var total: Double {
        items.reduce(0) { $0 + $1.lastKnownPrice * Double($1.quantity) }
    }

    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public func quantity(forItemId id: Int) -> Int {
        items.first { $0.id == id }?.quantity ?? 0
    }

    // MARK: - How the bag changes

    /// Choosing something already in the bag takes another of it. There is one line per
    /// product, and it carries the price the shopper was shown most recently — taking a
    /// second one at today's price does not leave the first sitting at last week's.
    public func adding(_ item: BagItem) -> Bag {
        guard let existing = items.first(where: { $0.id == item.id }) else {
            return Bag(items: items + [item])
        }
        return replacing(
            existing
                .withQuantity(existing.quantity + item.quantity)
                .withPrice(item.lastKnownPrice)
        )
    }

    public func removing(itemId: Int) -> Bag {
        Bag(items: items.filter { $0.id != itemId })
    }

    /// Asking for none of something is how a shopper puts it back, and asking about
    /// something that isn't in the bag changes nothing.
    public func changingQuantity(ofItemId id: Int, to quantity: Int) -> Bag {
        guard quantity > 0 else { return removing(itemId: id) }
        guard let existing = items.first(where: { $0.id == id }) else { return self }
        return replacing(existing.withQuantity(quantity))
    }

    private func replacing(_ item: BagItem) -> Bag {
        Bag(items: items.map { $0.id == item.id ? item : $0 })
    }
}
