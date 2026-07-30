import Foundation
import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 9 — Liskov Substitution Principle: decorators standing
/// in for the real use cases. Nothing below the app layer knows a demo is possible — `Component/Bag`
/// sees ordinary catalog answers and reacts exactly as it would in production.
///
/// One decision per product, taken from its id, so the demo is deterministic: it can be repeated and
/// a screenshot reproduced. Every path the app reads products through is decorated, so a product
/// reads the same on a card, in a search result, on its own page and in the bag. A demo that only
/// dressed one screen would prove nothing about the others.
enum DemoShop {
    /// What the shop has decided about one product.
    ///
    /// `soldOut` is true of a product wherever it appears. The rest are things the shop has changed
    /// its mind about *since the shopper looked*, and are only ever said to `lookUpProducts`.
    enum Mood {
        /// Run out, and says so everywhere: a bell on its card where the bag button would be, Notify
        /// Me on its page, and the Out Of Stock section if a shopper is holding one.
        case soldOut

        /// In stock when it went into the bag, gone when the bag asked again.
        ///
        /// It has to be this way round. A shopper cannot put something out of stock into a bag — the
        /// card offers a bell instead — so a product the demo called sold out everywhere could never
        /// reach a bag, and the bag's own notice about it would be unreachable.
        case soldOutSinceYouLooked

        /// Same reason, more so: the shop does not list what it has stopped selling, so a product
        /// the demo called discontinued everywhere would be filtered out of every grid and its page
        /// would be `.notFound`. Which is the rule working — but it leaves nothing to demonstrate.
        case discontinuedSinceYouLooked

        case dearerThanYouPaid
        case cheaperThanYouPaid

        /// Say one left, so a bag holding two or more is told it can have one.
        case fewerLeftThanYouWanted

        case ordinary
    }

    /// Ten buckets, so roughly half a page of products is interesting and the rest is a shop.
    nonisolated static func mood(of id: ProductID) -> Mood {
        switch id.rawValue % 10 {
        case 0: .discontinuedSinceYouLooked
        case 1: .dearerThanYouPaid
        case 2: .cheaperThanYouPaid
        case 3: .soldOut
        case 4: .fewerLeftThanYouWanted
        case 5: .soldOutSinceYouLooked
        default: .ordinary
        }
    }

    /// What the shop is selling now: a grid, a search, a category, a product's own page.
    ///
    /// Every mood is listed rather than defaulted, so a new one cannot be added without deciding
    /// what both reads say about it — which is the decision the demo exists to make.
    nonisolated static func onTheShelf(_ product: Product) -> Product {
        switch mood(of: product.id) {
        case .soldOut:
            copy(product, availability: .outOfStock)

        case .soldOutSinceYouLooked, .discontinuedSinceYouLooked, .dearerThanYouPaid,
                .cheaperThanYouPaid, .fewerLeftThanYouWanted, .ordinary:
            product
        }
    }

    /// What the shop says about something the shopper already holds — the bag's lookup, and the only
    /// read in the app that looks backwards.
    nonisolated static func askedAbout(_ product: Product) -> Product {
        switch mood(of: product.id) {
        case .soldOut, .soldOutSinceYouLooked:
            copy(product, availability: .outOfStock)

        case .discontinuedSinceYouLooked:
            copy(product, availability: .discontinued)

        case .dearerThanYouPaid:
            copy(product, price: scaled(product.price, by: 1.2))

        case .cheaperThanYouPaid:
            copy(product, price: scaled(product.price, by: 0.8))

        case .fewerLeftThanYouWanted:
            copy(product, availability: .inStock(remaining: 1))

        case .ordinary:
            product
        }
    }
}

// MARK: - Decorators

/// Grids, searches and categories all arrive here — `BrowseCatalogUseCase` is the one way the app
/// asks what is for sale, so decorating it is enough to dress every screen that browses.
struct DemoBrowseCatalogUseCase: BrowseCatalogUseCase {
    let wrapped: BrowseCatalogUseCase

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await wrapped(matching: query).map { $0.map(DemoShop.onTheShelf) }
    }
}

struct DemoViewProductUseCase: ViewProductUseCase {
    let wrapped: ViewProductUseCase

    func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        await wrapped(id: id).map(DemoShop.onTheShelf)
    }
}

struct DemoLookUpProductsUseCase: LookUpProductsUseCase {
    let wrapped: LookUpProductsUseCase

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped(ids: ids).map { $0.map(DemoShop.askedAbout) }
    }
}

// MARK: -

/// `Product` is a value with no mutating API, and giving it one for the sake of a demo would put a
/// convenience in the domain that only the app layer wants.
private nonisolated func copy(
    _ product: Product,
    price: Money? = nil,
    availability: Availability? = nil
) -> Product {
    Product(
        id: product.id,
        title: product.title,
        description: product.description,
        category: product.category,
        price: price ?? product.price,
        rating: product.rating,
        availability: availability ?? product.availability,
        brand: product.brand,
        thumbnail: product.thumbnail,
        images: product.images
    )
}

private nonisolated func scaled(_ amount: Money, by factor: Double) -> Money {
    Money(minorUnits: Int((Double(amount.minorUnits) * factor).rounded()), currency: amount.currency)
}
