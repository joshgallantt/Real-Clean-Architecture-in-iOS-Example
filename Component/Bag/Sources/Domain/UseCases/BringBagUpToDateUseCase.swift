import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// It asks the shop itself rather than being handed the answer. `PlaceOrderUseCase` reaches for
/// `GetSessionUseCase` the same way: a use case may compose another component's use cases, and
/// asking is part of catching up rather than something a screen does on its behalf.
///
/// That is also what makes silence mean something. A shop that has stopped selling a product does
/// not describe it — it stops answering for it — so hearing that requires knowing what was asked.
/// While a caller did the asking, "absent" and "never mentioned" arrived as the same input and this
/// had to guess; it guessed "leave it alone", which kept a line nobody could ever be sold.
///
/// What it heard is handed back, because the screen that draws names and pictures wants the same
/// answer. Asking twice over the same ids is a second round trip for a reply already received.
public protocol BringBagUpToDateUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction() async -> [Product]
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
    private let lookUpProducts: LookUpProductsUseCase

    public init(repository: BagRepository, lookUpProducts: LookUpProductsUseCase) {
        self.repository = repository
        self.lookUpProducts = lookUpProducts
    }

    @MainActor
    @discardableResult
    public func callAsFunction() async -> [Product] {
        let bagBefore = repository.bag
        let noticesBefore = repository.notices

        /// Everything on the shopper's screen, not only what the bag still holds: a notice that
        /// something has gone outlives the line it refers to, and the screen showing it still wants
        /// to know what the shop says about that product.
        let asked = Set(bagBefore.items.map(\.productId))
            .union(noticesBefore.all.map(\.productId))
        guard !asked.isEmpty else { return [] }

        /// A shop that could not be reached has said nothing at all, and nothing is concluded from
        /// nothing. Only an answer is evidence — which is what keeps a dropped connection from
        /// reading as a shop that has closed down and emptying the bag.
        guard case .success(let products) = await lookUpProducts(ids: Array(asked)) else { return [] }

        let (bag, notices) = Self.catchUp(
            bag: bagBefore,
            notices: noticesBefore,
            against: products,
            asked: asked
        )

        if bag != bagBefore || notices != noticesBefore {
            repository.save(bag: bag, notices: notices)
        }

        return products
    }

    /// Evans, *Domain-Driven Design* (2003), Ch. 10 — Side-Effect-Free Functions: the whole catch-up
    /// as one answer, a line at a time. Every line the shopper had either stays — at whatever the
    /// shop now charges, and never for more than the shop can supply — or it has gone, and says
    /// which of the two ways it went.
    static func catchUp(
        bag: Bag,
        notices: Notices,
        against products: [Product],
        asked: Set<ProductID>
    ) -> (bag: Bag, notices: Notices) {
        let shop = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        var kept: [BagItem] = []
        var news: [Notice] = []

        /// What has already gone stays gone: being told a second time is not a second piece of news.
        /// These outlive the lines they are about, which is the whole point of them, so they are
        /// carried over rather than rebuilt from a bag that no longer holds the product.
        var gone = notices.gone

        for line in bag.items {
            guard let says = shop[line.productId] else {
                guard asked.contains(line.productId) else {
                    /// Not asked about, so nothing has been learned. It stays as it was, and so does
                    /// anything it was already owed word about.
                    kept.append(line)
                    news.append(contentsOf: notices.about(line.productId).filter { !$0.isAboutSomethingGone })
                    continue
                }

                /// Asked about and not described. The shop has stopped selling it.
                if !gone.contains(where: { $0.productId == line.productId }) {
                    gone.append(.discontinued(productId: line.productId))
                }
                continue
            }

            guard says.availability.isAvailable else {
                if !gone.contains(where: { $0.productId == line.productId }) {
                    gone.append(.outOfStock(productId: line.productId))
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
        nowThatTheShopSays says: Product,
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
}
