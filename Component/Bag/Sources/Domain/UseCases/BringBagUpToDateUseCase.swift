import Money
import Product

public protocol BringBagUpToDateUseCase: Sendable {
    /// Brings the bag up to date with what the catalog currently says. Covering only
    /// some of the bag is fine — the rest is left alone.
    @MainActor
    func callAsFunction(against shopSays: [ShopSays])
}

/// Bringing a bag up to date with what the shop now says, and working out what the shopper
/// needs to be told.
///
/// This is application work, not a rule the bag or the notices own: it reads both, decides
/// what to do about the difference, and writes both back. Neither aggregate can do it —
/// the bag knows what a line cost but not what price the shopper last *saw*, and the notices
/// know that but hold no lines — and a third domain type holding the logic would just be a
/// use case that cannot be injected or substituted.
///
/// Advisory by design. It corrects prices, cuts lines down to what the shop can supply,
/// takes out what it cannot supply at all, and records why. Nothing here is final; what the
/// shopper pays is settled at checkout.
public struct DefaultBringBagUpToDateUseCase: BringBagUpToDateUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(against shopSays: [ShopSays]) {
        let current = repository.bag
        let currentChanges = repository.changes
        let updated = Self.reconcile(bag: current, changes: currentChanges, against: shopSays)

        // Saving an unchanged bag would wake everything watching it for nothing, and on a
        // screen that does this every time it appears, that is most of the time.
        guard updated.bag != current || updated.changes != currentChanges else { return }
        repository.save(bag: updated.bag, changes: updated.changes)
    }

    /// - Parameter shopSays: what the catalog currently says, for however many of the bag's
    ///   products were looked up. A product the shop said nothing about was not asked
    ///   about — never that it is gone — so its line is left exactly as it is.
    static func reconcile(
        bag: Bag,
        changes: BagChanges,
        against shopSays: [ShopSays]
    ) -> (bag: Bag, changes: BagChanges) {
        let catalog = Dictionary(shopSays.map { ($0.productId, $0) }, uniquingKeysWith: { _, last in last })
        var keptItems: [BagItem] = []
        var news: [BagChange] = []
        var gone = changes.noLongerAvailable

        for item in bag.items {
            guard let says = catalog[item.productId] else {
                // The shop was not asked about this one. Leave the line, and leave
                // whatever was already waiting to be said about it still waiting.
                news.append(contentsOf: changes.about(productId: item.productId).filter(\.isAboutAProductStillInTheBag))
                keptItems.append(item)
                continue
            }

            // A bag is what the shopper is going to buy, and a line that cannot be bought
            // does not belong in it. What its price did on the way out is not news.
            guard says.availability.isAvailable else {
                if !gone.contains(where: { $0.productId == item.productId }) {
                    gone.append(.noLongerAvailable(productId: item.productId))
                }
                continue
            }

            // Measured from what the shopper last saw, so a price that moves twice while
            // they are away reads as one move, and one that moves back stops being news.
            let priceTheyKnow = changes.priceLastSeen(forProductId: item.productId) ?? item.lastKnownPrice
            if let move = BagChange.priceMove(productId: item.productId, from: priceTheyKnow, to: says.price) {
                news.append(move)
            }

            // Asking for more than the shop has is not something to discover at checkout.
            // The line comes down to what can actually be supplied, and that is said out
            // loud rather than left as a count that changed on its own.
            let available = says.availability.remaining
            if item.quantity > available {
                news.append(.onlySomeLeft(productId: item.productId, available: available))
                keptItems.append(item.withPrice(says.price).withQuantity(available))
            } else {
                keptItems.append(item.withPrice(says.price))
            }
        }

        return (Bag(items: keptItems), BagChanges(news + gone))
    }
}
