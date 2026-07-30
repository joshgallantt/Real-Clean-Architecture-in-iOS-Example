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

        /// Stopped selling. Not listed, no page, and No Longer Available in a bag holding one —
        /// which is the app's rule about the real shop, working.
        case discontinued

        /// One left, so a bag holding more is told it can have one.
        case nearlyGone

        case dearer
        case cheaper
    }

    /// Which products get which mood, rotated by a number drawn once at launch.
    ///
    /// The rotation is the whole demo. A shop that decided the same thing every time would agree
    /// with the bag it filled last time, and a bag is only worth looking at when it disagrees:
    /// prices move, things sell out, and things stop being sold *between* one visit and the next.
    /// So the bag's before is what a shopper paid, which is on disk, and the after is this — and
    /// nothing has to be told a different story to make a notice appear.
    let offset: Int

    init(offset: Int = Int.random(in: 0..<10)) {
        self.offset = offset
    }

    func mood(of id: ProductID) -> Mood {
        switch (id.rawValue + offset) % 10 {
        case 0: .discontinued
        case 1: .dearer
        case 2: .cheaper
        case 3: .soldOut
        case 4: .nearlyGone
        case 5: .soldOut
        default: .ordinary
        }
    }

    /// The product as this shop is selling it today. Every read goes through here, so this is what
    /// the grid shows, what the page shows, and what the bag is told when it asks.
    func asItIsToday(_ product: Product) -> Product {
        switch mood(of: product.id) {
        case .ordinary:
            product

        case .soldOut:
            copy(product, availability: .outOfStock)

        case .discontinued:
            copy(product, availability: .discontinued)

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
        await wrapped.getProducts(matching: query).map { $0.map(shop.asItIsToday) }
    }

    func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped.getProducts(ids: ids).map { $0.map(shop.asItIsToday) }
    }

    func getProduct(id: ProductID) async -> Result<Product, ProductError> {
        await wrapped.getProduct(id: id).map(shop.asItIsToday)
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
