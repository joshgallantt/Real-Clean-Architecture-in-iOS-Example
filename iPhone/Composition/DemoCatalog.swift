import Foundation
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
//  The same rules are asserted without any of this in BagReconciliationTests
//  and PendingChangeTests.
// ─────────────────────────────────────────────────────────────────────────────

/// How the fake shop misbehaves. Deterministic, so a demo can be repeated and a
/// screenshot reproduced.
enum DemoCatalogMischief {
    /// Every third product costs more, every third costs less, every fifth has sold out,
    /// and every tenth is gone for good — enough overlap that some lines report two
    /// changes at once, and both out-of-stock endings are reachable.
    nonisolated static func meddle(with product: Product) -> Product {
        let price = switch product.id % 3 {
        case 0: (product.price * 1.2).toTheNearestPenny
        case 1: (product.price * 0.8).toTheNearestPenny
        default: product.price
        }

        return Product(
            id: product.id,
            title: product.title,
            description: product.description,
            category: product.category,
            price: price,
            discountPercentage: product.discountPercentage,
            rating: product.rating,
            stock: product.id % 5 == 0 ? 0 : product.stock,
            willRestock: product.id % 10 != 0,
            brand: product.brand,
            thumbnail: product.thumbnail,
            images: product.images
        )
    }
}

// MARK: - Decorators

/// DEMO ONLY. Wraps the real use case and meddles with its answers.
struct DemoGetProductsUseCase: GetProductsUseCase {
    let wrapped: GetProductsUseCase

    func callAsFunction(matching query: ProductQuery) async -> Result<[Product], ProductError> {
        await wrapped(matching: query).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

/// DEMO ONLY. This is the one the bag reads when it catches up, so it is the one
/// that produces the Changed section.
struct DemoGetProductsByIdsUseCase: GetProductsByIdsUseCase {
    let wrapped: GetProductsByIdsUseCase

    func callAsFunction(ids: [Int]) async -> Result<[Product], ProductError> {
        await wrapped(ids: ids).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

/// DEMO ONLY.
struct DemoGetProductUseCase: GetProductUseCase {
    let wrapped: GetProductUseCase

    func callAsFunction(id: Int) async -> Result<Product, ProductError> {
        await wrapped(id: id).map(DemoCatalogMischief.meddle)
    }
}

private extension Double {
    nonisolated var toTheNearestPenny: Double { (self * 100).rounded() / 100 }
}
