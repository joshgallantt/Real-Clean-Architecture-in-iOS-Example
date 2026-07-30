import Product

/// Bringing a bag up to date with what the shop now says, and working out what the
/// shopper needs to be told.
///
/// A service rather than a method on either thing it touches, because it is not a natural
/// responsibility of either: it needs the bag to know what a line cost and the change list
/// to know what price the shopper last *saw*, and it produces a new version of both. It
/// holds no state of its own.
///
/// Advisory by design. It corrects prices, takes out what cannot be supplied, and records
/// why — nothing here is final. What the shopper pays is settled at checkout.
public enum BagReconciliation {

    /// - Parameter products: what the catalog currently says, for however many of the
    ///   bag's products were looked up. A product missing from this list was not asked
    ///   about — never that it is gone — so its line is left exactly as it is.
    public static func reconcile(
        bag: Bag,
        changes: BagChanges,
        against products: [Product]
    ) -> (bag: Bag, changes: BagChanges) {
        let catalog = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        var keptItems: [BagItem] = []
        var priceMoves: [BagChange] = []
        var gone = changes.noLongerAvailable

        for item in bag.items {
            guard let product = catalog[item.productId] else {
                // The shop was not asked about this one. Leave the line, and leave
                // whatever was already waiting to be said about it still waiting.
                priceMoves.append(contentsOf: changes.about(productId: item.productId).filter(\.isAboutAProductStillInTheBag))
                keptItems.append(item)
                continue
            }

            // A bag is what the shopper is going to buy, and a line that cannot be bought
            // does not belong in it. What its price did on the way out is not news.
            // Stock is a count to the shop and a yes-or-no to a bag.
            guard product.isInStock else {
                if !gone.contains(where: { $0.productId == item.productId }) {
                    gone.append(.noLongerAvailable(productId: item.productId))
                }
                continue
            }

            // Measured from what the shopper last saw, so a price that moves twice while
            // they are away reads as one move, and one that moves back stops being news.
            let priceTheyKnow = changes.priceLastSeen(forProductId: item.productId) ?? item.lastKnownPrice
            if let move = BagChange.priceMove(productId: item.productId, from: priceTheyKnow, to: product.price) {
                priceMoves.append(move)
            }
            keptItems.append(item.withPrice(product.price))
        }

        return (Bag(items: keptItems), BagChanges(priceMoves + gone))
    }

    /// The changes still worth telling the shopper about, given what is in their bag now.
    ///
    /// A price is news about something they are buying, so a price move about a line no
    /// longer in the bag is news about nothing. A product being gone is news about
    /// something absent, so it only stands while it is absent — choose it again and there
    /// is nothing to report.
    ///
    /// Decided when the changes are read rather than when they are written. `Bag` and
    /// `BagChanges` are kept together but written one after the other, and a process that
    /// dies in between would leave the pair disagreeing. Deciding on the way out means the
    /// disagreement corrects itself instead of persisting.
    public static func worthTelling(_ changes: BagChanges, about bag: Bag) -> BagChanges {
        BagChanges(
            changes.all.filter { change in
                change.isAboutAProductStillInTheBag == bag.holds(productId: change.productId)
            }
        )
    }
}
