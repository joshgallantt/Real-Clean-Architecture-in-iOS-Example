import Foundation
import Networking
import Product
import ProductData
import ProductDI

/// Martin, *Clean Architecture* (2017), Ch. 8 — Open/Closed Principle: a demo is added by writing a
/// new `Catalog`, not by editing `CompositionRoot`. The exemplar stays the thing worth reading, and
/// a demo cannot leak into it.
///
/// Martin, Ch. 26 — The Main Component: a second composition root, chosen at the one line in
/// `CompositionRoot.shared`. Both arrangements compile at all times, so a demo cannot rot and
/// switching one on is never a matter of uncommenting code.
///
/// To run it, change `CompositionRoot.shared` to:
///
///     static let shared = CompositionRoot(catalog: DemoCompositionRoot.shopThatChangesItsMind())
///
/// Then: add three or four things to the bag with the demo off, switch it on, rebuild, and open the
/// Bag tab. Prices have moved, some lines are short, some have gone. Tap Okay on one and it stays;
/// tap Remove on another and it goes with its notice. Relaunch and the notices a shopper never read
/// are still waiting, because they are kept with the bag.
enum DemoCompositionRoot {

    /// A shop that has changed its mind since the shopper last looked.
    static func shopThatChangesItsMind() -> Catalog {
        let productDI = ProductDI(
            client: DummyJSONProductClient(httpClient: URLSessionHTTPClient(session: .shared))
        )
        return Catalog(
            browseCatalog: DemoBrowseCatalogUseCase(wrapped: productDI.browseCatalogUseCase),
            lookUpProducts: DemoLookUpProductsUseCase(wrapped: productDI.lookUpProductsUseCase),
            viewProduct: DemoViewProductUseCase(wrapped: productDI.viewProductUseCase),
            browseCategories: productDI.browseCategoriesUseCase
        )
    }
}
