import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
public protocol BringBagUpToDateUseCase: Sendable {
    @MainActor
    func callAsFunction(against shopSays: [ShopSays])
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: application work, not a rule either
/// aggregate owns. It reads both and writes both — the bag knows what a line cost but not what price
/// the shopper last *saw*; the notices know that but hold no lines. A third domain type holding this
/// would be a use case that cannot be injected or substituted.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: behaviour belonging to no single
/// aggregate, and holding no state.
public struct DefaultBringBagUpToDateUseCase: BringBagUpToDateUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(against shopSays: [ShopSays]) {
        let bagBefore = repository.bag
        let noticesBefore = repository.notices
        let (bag, notices) = Self.catchUp(bag: bagBefore, notices: noticesBefore, against: shopSays)

        guard bag != bagBefore || notices != noticesBefore else { return }
        repository.save(bag: bag, notices: notices)
    }

    /// Evans, *Domain-Driven Design* (2003), Ch. 10 — Side-Effect-Free Functions: the whole catch-up
    /// as one answer, a line at a time. Every line the shopper had either stays — at whatever the
    /// shop now charges, and never for more than the shop can supply — or it has gone, and says
    /// which of the two ways it went.
    static func catchUp(
        bag: Bag,
        notices: Notices,
        against shopSays: [ShopSays]
    ) -> (bag: Bag, notices: Notices) {
        let shop = Dictionary(shopSays.map { ($0.productId, $0) }, uniquingKeysWith: { _, latest in latest })
        var kept: [BagItem] = []
        var news: [Notice] = []

        /// What has already gone stays gone: being told a second time is not a second piece of news.
        /// These outlive the lines they are about, which is the whole point of them, so they are
        /// carried over rather than rebuilt from a bag that no longer holds the product.
        var gone = notices.gone

        for line in bag.items {
            guard let says = shop[line.productId] else {
                /// The shop was not asked about this one, so nothing about it has been learned. It
                /// stays as it was, and so does anything it was already owed word about.
                kept.append(line)
                news.append(contentsOf: notices.about(line.productId).filter { !$0.isAboutSomethingGone })
                continue
            }

            guard says.availability.isAvailable else {
                if !gone.contains(where: { $0.productId == line.productId }) {
                    gone.append(Self.howItWent(line.productId, says.availability))
                }
                continue
            }

            news.append(contentsOf: Self.news(about: line, nowThatTheShopSays: says, given: notices))
            kept.append(
                line
                    .withPrice(says.price)
                    .withQuantity(min(line.quantity, says.availability.remaining))
            )
        }

        return (Bag(items: kept), Notices(news + gone))
    }

    /// Two facts about a line the shopper still has, told apart because they are two facts: what it
    /// costs now, if that is not what they were last shown, and how many are left, if they asked for
    /// more than that.
    private static func news(
        about line: BagItem,
        nowThatTheShopSays says: ShopSays,
        given notices: Notices
    ) -> [Notice] {
        var news: [Notice] = []

        /// Against the price the shopper was last *shown*, not the one on the line. A notice still
        /// waiting means they have not seen the line's price yet, so two moves before they look read
        /// as one move from what they knew.
        let priceTheyKnow = notices.priceLastSeen(forProductId: line.productId) ?? line.lastKnownPrice
        if let move = Notice.priceMove(productId: line.productId, from: priceTheyKnow, to: says.price) {
            news.append(move)
        }

        if line.quantity > says.availability.remaining {
            news.append(.onlySomeLeft(productId: line.productId, available: says.availability.remaining))
        }

        return news
    }

    /// A shopper reads the two ways of going completely differently — one is worth waiting for and
    /// the other is not — so the bag records which, rather than only that it is gone.
    private static func howItWent(_ productId: ProductID, _ availability: Availability) -> Notice {
        availability == .discontinued
            ? .discontinued(productId: productId)
            : .outOfStock(productId: productId)
    }
}
