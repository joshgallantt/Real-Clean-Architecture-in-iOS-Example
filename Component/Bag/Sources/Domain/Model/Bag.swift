import Foundation

/// The shopper's bag: what is in it, what it is worth, what has changed since they last
/// looked, and every rule about how all of that changes.
///
/// Everything inside the bag changes through the bag. A caller that reached in to
/// rearrange the lines itself could put the bag into a state the bag would not allow —
/// two lines for the same product, a line with none of it, an order that isn't newest
/// first — so the only way in is through these.
///
/// The total is computed from the last prices the shopper was shown, so it is there on
/// a dead connection. It is the best available answer, not a promise: what the shopper
/// pays is settled at checkout against the shop's prices.
public struct Bag: Equatable, Sendable {
    public let items: [BagItem]

    /// What has moved since the shopper last said they had seen it. Kept with the bag
    /// rather than handed out once, because a shopper who backgrounds the app mid-notice
    /// is owed it again next time.
    public let pendingChanges: [BagChange]

    /// Newest first is the bag's own order, so it is established here rather than
    /// trusted from whatever handed the lines over. A warning about a line that is no
    /// longer in the bag is not a warning about anything.
    public init(items: [BagItem] = [], pendingChanges: [BagChange] = []) {
        let ordered = items.sorted { $0.dateAdded > $1.dateAdded }
        let present = Set(ordered.map(\.id))
        self.items = ordered
        self.pendingChanges = pendingChanges.filter { present.contains($0.itemId) }
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

    public var hasPendingChanges: Bool {
        !pendingChanges.isEmpty
    }

    public func quantity(forItemId id: Int) -> Int {
        items.first { $0.id == id }?.quantity ?? 0
    }

    public func changes(forItemId id: Int) -> [BagChange] {
        pendingChanges.filter { $0.itemId == id }
    }

    // MARK: - How the bag changes

    /// Choosing something already in the bag takes another of it. There is one line per
    /// product, and it carries the price the shopper was shown most recently — taking a
    /// second one at today's price does not leave the first sitting at last week's.
    ///
    /// Choosing something is also seeing its price, so a warning about it has already
    /// served its purpose.
    public func adding(_ item: BagItem) -> Bag {
        guard let existing = items.first(where: { $0.id == item.id }) else {
            return Bag(items: items + [item], pendingChanges: pendingChanges)
        }
        return replacing(
            existing
                .withQuantity(existing.quantity + item.quantity)
                .withPrice(item.lastKnownPrice)
        )
        .acknowledging(itemId: item.id)
    }

    public func removing(itemId: Int) -> Bag {
        Bag(
            items: items.filter { $0.id != itemId },
            pendingChanges: pendingChanges.filter { $0.itemId != itemId }
        )
    }

    /// Asking for none of something is how a shopper puts it back, and asking about
    /// something that isn't in the bag changes nothing.
    public func changingQuantity(ofItemId id: Int, to quantity: Int) -> Bag {
        guard quantity > 0 else { return removing(itemId: id) }
        guard let existing = items.first(where: { $0.id == id }) else { return self }
        return replacing(existing.withQuantity(quantity))
    }

    // MARK: - Catching up with the shop

    /// Brings the bag up to date with what the shop currently says, and records what
    /// moved so the shopper can be told rather than left to notice.
    ///
    /// Prices and availability are separate facts and arrive separately: a line can be
    /// repriced without its stock being known, and the other way round. A line the shop
    /// said nothing about is left exactly as it was — silence means the lookup did not
    /// cover it, never that the product is gone.
    ///
    /// A warning already waiting is folded into, not stacked on: a price that moves
    /// twice before the shopper looks reads as one move from what they knew. A price
    /// that moves back to where it started stops being news, and stock that returns
    /// retracts its own warning.
    ///
    /// This is advisory, and it never takes anything out. What the shopper pays, and
    /// whether an out-of-stock line can be fulfilled, is settled at checkout.
    public func reconciled(
        prices: [Int: Double] = [:],
        inStock: [Int: Bool] = [:]
    ) -> Bag {
        var updatedItems: [BagItem] = []
        var changes = pendingChanges

        for item in items {
            if let price = prices[item.id] {
                let lastSeen = changes.first { $0.itemId == item.id && $0.isPriceChange }?
                    .priceLastSeen ?? item.lastKnownPrice

                changes.removeAll { $0.itemId == item.id && $0.isPriceChange }
                if let change = BagChange.price(itemId: item.id, from: lastSeen, to: price) {
                    changes.append(change)
                }
            }

            switch inStock[item.id] {
            case false:
                if !changes.contains(.outOfStock(itemId: item.id)) {
                    changes.append(.outOfStock(itemId: item.id))
                }
            case true:
                changes.removeAll { $0 == .outOfStock(itemId: item.id) }
            case nil:
                break
            }

            updatedItems.append(prices[item.id].map(item.withPrice) ?? item)
        }

        return Bag(items: updatedItems, pendingChanges: ordered(changes, by: updatedItems))
    }

    /// The shopper has seen what happened to this line.
    public func acknowledging(itemId: Int) -> Bag {
        Bag(items: items, pendingChanges: pendingChanges.filter { $0.itemId != itemId })
    }

    public func acknowledgingAllChanges() -> Bag {
        Bag(items: items, pendingChanges: [])
    }

    // MARK: -

    private func replacing(_ item: BagItem) -> Bag {
        Bag(items: items.map { $0.id == item.id ? item : $0 }, pendingChanges: pendingChanges)
    }

    /// Reported in the order the shopper reads their bag, so the warnings and the lines
    /// they refer to run the same way down the screen.
    private func ordered(_ changes: [BagChange], by items: [BagItem]) -> [BagChange] {
        let position = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, $0) })
        return changes.sorted { position[$0.itemId, default: 0] < position[$1.itemId, default: 0] }
    }
}
