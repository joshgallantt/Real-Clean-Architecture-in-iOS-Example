import Foundation
import Money
import Product

/// What the demo shop is like this time the app was opened.
///
/// One decision per product, and it is the answer to every question about that product for as long
/// as the app is running. A shopper cannot be sold something on a card that the bag then calls sold
/// out, because there is nowhere for the two to disagree — see `DemoProductRepository`.
///
/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the offset is drawn here, at
/// launch, by the only layer allowed to decide such things.
nonisolated struct DemoShop: Sendable {
    enum Mood {
        case ordinary

        /// Run out, coming back. A bell on its card where the bag button would be, Notify Me on its
        /// page, and Out Of Stock in a bag that was holding one.
        case soldOut

        /// Stopped selling. This shop does not return it at all — not in a list, not by id — which
        /// is how a real shop stops selling something, and how a bag holding one finds out.
        case gone

        /// One left, so a bag holding more is told it can have one.
        case nearlyGone

        case dearer
        case cheaper
    }

    /// Which products get which mood, rotated by which visit this is.
    ///
    /// The rotation is the whole demo. A shop that decided the same thing every time would agree
    /// with the bag it filled last time, and a bag is only worth looking at when it disagrees:
    /// prices move, things sell out, and things stop being sold *between* one visit and the next.
    /// So the bag's before is what a shopper paid, which is on disk, and the after is this — and
    /// nothing has to be told a different story to make a notice appear.
    ///
    /// One step per visit, not a number drawn at random. Look at the wheel below and every mood
    /// steps somewhere useful: both sold-out slots land on an in-stock one, so anything waitlisted
    /// last visit is *guaranteed* back this visit rather than back if the dice agreed. A random
    /// offset made the waitlist demo a coin flip, and a demo nobody can rely on seeing is one that
    /// gets called broken.
    let offset: Int

    init(offset: Int) {
        self.offset = offset
    }

    /// The wheel. Read it as what happens *next* visit as much as what is true this one: gone
    /// becomes dearer, sold out becomes nearly gone, nearly gone sells out again, and ordinary
    /// eventually goes. Every kind of news this app can show is one step somewhere on it.
    func mood(of id: ProductID) -> Mood {
        switch (id.rawValue + offset) % 10 {
        case 0: .gone
        case 1: .dearer
        case 2: .cheaper
        case 3: .soldOut
        case 4: .nearlyGone
        case 5: .soldOut
        default: .ordinary
        }
    }

    /// Whether this shop still sells it at all. Answered by withholding the product rather than by
    /// describing it, because that is the only signal a shop that has stopped selling something
    /// actually gives.
    func isStillSold(_ id: ProductID) -> Bool {
        mood(of: id) != .gone
    }

    /// The product as this shop is selling it today. Every read goes through here, so this is what
    /// the grid shows, what the page shows, and what the bag is told when it asks.
    func asItIsToday(_ product: Product) -> Product {
        switch mood(of: product.id) {
        case .ordinary, .gone:
            product

        case .soldOut:
            copy(product, availability: .outOfStock)

        case .nearlyGone:
            copy(product, availability: .inStock(remaining: 1))

        case .dearer:
            copy(product, price: scaled(product.price, by: 1.2))

        case .cheaper:
            copy(product, price: scaled(product.price, by: 0.8))
        }
    }
}

// MARK: -

/// Martin, *Clean Architecture* (2017), Ch. 9 — Liskov Substitution Principle: a repository standing
/// in for the real one. Nothing inward knows a demo is possible — the use cases, the bag and the
/// wishlist see ordinary catalog answers and behave exactly as they would in production.
///
/// One seam, deliberately. Decorating the use cases meant four places to remember and four chances
/// to answer differently, and it took them: browsing was left alone while the bag's lookup was
/// meddled with, so the catalog sold a shopper something the bag then called out of stock. Below
/// the use cases there is one door, and everything comes through it.
struct DemoProductRepository: ProductRepository {
    let wrapped: ProductRepository
    let shop: DemoShop

    func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await wrapped.getProducts(matching: query)
            .map { $0.filter { shop.isStillSold($0.id) }.map(shop.asItIsToday) }
    }

    func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped.getProducts(ids: ids)
            .map { $0.filter { shop.isStillSold($0.id) }.map(shop.asItIsToday) }
    }

    /// Gone means gone, by id as well as in a list. A shop that hid something from its shelves but
    /// still served its page would not be one the bag could learn anything from.
    func getProduct(id: ProductID) async -> Result<Product, ProductError> {
        guard shop.isStillSold(id) else { return .failure(.notFound) }
        return await wrapped.getProduct(id: id).map(shop.asItIsToday)
    }

    /// A category is a shelf, not a product. There is nothing here to change.
    func getCategories() async -> Result<[ProductCategory], ProductError> {
        await wrapped.getCategories()
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
