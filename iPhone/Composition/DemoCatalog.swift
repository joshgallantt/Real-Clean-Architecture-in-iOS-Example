import Foundation
import Money
import Product

// ─────────────────────────────────────────────────────────────────────────────
//  DEMO ONLY — NOT PART OF THE APP
//
//  Scaffolding for showing off the bag's "catching up with the shop" behaviour
//  without waiting for a real shop to change its mind. It lies about prices and
//  stock so that reopening the bag produces the Changed section on demand.
//
//  It exists here, in the composition root, and nowhere else. `Component/Product`
//  has no idea it is possible; `Component/Bag` sees ordinary catalog answers and
//  reacts exactly as it would in production. Nothing below the app layer is aware
//  of a demo mode, and deleting this file plus its three lines in `Injector`
//  removes the feature completely.
//
//  Off unless switched on by hand in `Injector.init` — look for the commented
//  block next to the catalog use cases.
//
//  To demo it:
//    1. With the demo OFF, add three or four things to the bag from Home or a
//       category. Spread the ids so the rules below hit differently.
//    2. Switch the demo ON in `Injector`, rebuild, and open the Bag tab.
//       The snackbar fires once, and a Changed section lists what moved. Nothing
//       is removed; the total moves to the new prices.
//    3. Tap Okay on one line — it leaves the section and stays in the bag. Tap
//       Remove on another — the item and its warning both go.
//    4. Relaunch. The remaining warnings are still there: pending changes are
//       persisted with the bag, so a shopper who never read the notice is owed
//       it again.
//
//  Also worth showing: turn on airplane mode and reopen the bag — names and
//  pictures go blank, the total is still exactly right, and no error appears.
//
//  The same rules are asserted without any of this in BringingTheBagUpToDateTests.
// ─────────────────────────────────────────────────────────────────────────────

/// How the fake shop misbehaves. Deterministic, so a demo can be repeated and a
/// screenshot reproduced.
enum DemoCatalogMischief {
    /// Every third product costs more, every third costs less, every fifth has sold out,
    /// and every tenth is gone for good — enough overlap that some lines report two
    /// changes at once, and both kinds of unavailability are reachable.
    nonisolated static func meddle(with product: Product) -> Product {
        let price = switch product.id.rawValue % 3 {
        case 0: product.price.scaled(by: 1.2)
        case 1: product.price.scaled(by: 0.8)
        default: product.price
        }

        let availability: Availability = if product.id.rawValue % 10 == 0 {
            .discontinued
        } else if product.id.rawValue % 5 == 0 {
            .outOfStock
        } else {
            product.availability
        }

        return Product(
            id: product.id,
            title: product.title,
            description: product.description,
            category: product.category,
            price: price,
            rating: product.rating,
            availability: availability,
            brand: product.brand,
            thumbnail: product.thumbnail,
            images: product.images
        )
    }
}

// MARK: - Decorators

/// DEMO ONLY. Wraps the real use case and meddles with its answers.
struct DemoBrowseCatalogUseCase: BrowseCatalogUseCase {
    let wrapped: BrowseCatalogUseCase

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await wrapped(matching: query).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

/// DEMO ONLY. This is the one the bag reads when it catches up, so it is the one
/// that produces the Changed section.
struct DemoLookUpProductsUseCase: LookUpProductsUseCase {
    let wrapped: LookUpProductsUseCase

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped(ids: ids).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

/// DEMO ONLY.
struct DemoViewProductUseCase: ViewProductUseCase {
    let wrapped: ViewProductUseCase

    func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        await wrapped(id: id).map(DemoCatalogMischief.meddle)
    }
}

private extension Money {
    /// Rounded to a whole minor unit, because a fifth of a penny is not a price.
    nonisolated func scaled(by factor: Double) -> Money {
        Money(minorUnits: Int((Double(minorUnits) * factor).rounded()), currency: currency)
    }
}
