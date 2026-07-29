/// Bringing a bag up to date with what the shop now says, and working out what the
/// shopper needs to be told.
///
/// A service rather than a method, because it is not a natural responsibility of either
/// thing it touches: it needs the bag to know what a line cost and the change list to
/// know what price the shopper last *saw*, and it produces a new version of both. It
/// holds no state of its own.
///
/// Advisory by design. It corrects prices, takes out what cannot be supplied, and
/// records why — it does not decide anything final.
public enum BagReconciliation {

    /// - Parameters:
    ///   - prices: what the shop is asking now, for however many products were looked up.
    ///   - inStock: whether each can be supplied. Silence about a product means the
    ///     lookup did not cover it, never that it is gone.
    public static func catchUp(
        bag: Bag,
        changes: BagChanges,
        prices: [Int: Double] = [:],
        inStock: [Int: Bool] = [:]
    ) -> (bag: Bag, changes: BagChanges) {
        var keptItems: [BagItem] = []
        var priceChanges: [BagChange] = []
        var removals = changes.removals

        for item in bag.items {
            // Something the shop cannot supply leaves the bag: a bag is what the shopper
            // is going to buy, and a line that cannot be bought does not belong in it.
            // What its price did on the way out is not news.
            if inStock[item.id] == false {
                if !removals.contains(where: { $0.itemId == item.id }) {
                    removals.append(.outOfStock(itemId: item.id))
                }
                continue
            }

            guard let price = prices[item.id] else {
                // Not looked up. Leave the line, and leave whatever was already pending
                // about it still pending.
                priceChanges.append(contentsOf: changes.changes(forItemId: item.id).filter(\.isPriceChange))
                keptItems.append(item)
                continue
            }

            // Measured from what the shopper last saw, so a price that moves twice while
            // they are away reads as one move, and one that moves back stops being news.
            let lastSeen = changes.priceLastSeen(forItemId: item.id) ?? item.lastKnownPrice
            if let change = BagChange.price(itemId: item.id, from: lastSeen, to: price) {
                priceChanges.append(change)
            }
            keptItems.append(item.withPrice(price))
        }

        return (Bag(items: keptItems), BagChanges(priceChanges + removals))
    }

    /// The notices that still make sense against this bag.
    ///
    /// A price is news about something the shopper is buying, so a price notice for a
    /// line no longer in the bag is news about nothing. A removal is news about something
    /// that has gone, so it only stands while the line is absent — choose the product
    /// again and there is nothing to report.
    ///
    /// Applied when the notices are read rather than when they are written. `Bag` and
    /// `BagChanges` are kept together but written one after the other, and a process that
    /// dies in between would leave the pair disagreeing. Deciding this on the way out
    /// means the disagreement corrects itself instead of persisting.
    public static func applicable(_ changes: BagChanges, to bag: Bag) -> BagChanges {
        let present = Set(bag.items.map(\.id))

        return BagChanges(
            changes.all.filter { change in
                change.isPriceChange
                    ? present.contains(change.itemId)
                    : !present.contains(change.itemId)
            }
        )
    }
}
