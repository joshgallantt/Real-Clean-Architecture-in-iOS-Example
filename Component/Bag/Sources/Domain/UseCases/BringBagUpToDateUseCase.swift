import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
public protocol BringBagUpToDateUseCase: Sendable {
    @MainActor
    func callAsFunction(against shopSays: [ShopSays])
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: application work, not a rule
/// either aggregate owns. It reads both and writes both — the bag knows what a line cost but not
/// what price the shopper last *saw*; the notices know that but hold no lines. A third domain type
/// holding this would be a use case that cannot be injected or substituted.
///
/// Evans, *Domain-Driven Design* (2003) — Services: behaviour belonging to no single aggregate, and
/// holding no state.
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

        guard updated.bag != current || updated.changes != currentChanges else { return }
        repository.save(bag: updated.bag, changes: updated.changes)
    }

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
                news.append(contentsOf: changes.about(productId: item.productId).filter(\.isAboutAProductStillInTheBag))
                keptItems.append(item)
                continue
            }

            guard says.availability.isAvailable else {
                if !gone.contains(where: { $0.productId == item.productId }) {
                    gone.append(.noLongerAvailable(productId: item.productId))
                }
                continue
            }

            let priceTheyKnow = changes.priceLastSeen(forProductId: item.productId) ?? item.lastKnownPrice
            if let move = BagChange.priceMove(productId: item.productId, from: priceTheyKnow, to: says.price) {
                news.append(move)
            }

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
