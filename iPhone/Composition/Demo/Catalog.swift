import Foundation
import Networking
import Product
import ProductData
import ProductDI

/// Martin, *Clean Architecture* (2017), Ch. 8 — Open/Closed Principle: the seam a demo varies
/// without editing the composition root. A demo supplies a different `Catalog`; nothing in
/// `CompositionRoot` changes, and both arrangements compile at all times.
///
/// Martin, Ch. 9 — Liskov Substitution Principle: a meddling catalog stands in for the real one
/// because both are the same set of use case protocols. Nothing downstream can tell.
struct Catalog {
    let browseCatalog: BrowseCatalogUseCase
    let lookUpProducts: LookUpProductsUseCase
    let viewProduct: ViewProductUseCase
    let browseCategories: BrowseCategoriesUseCase

    init(
        browseCatalog: BrowseCatalogUseCase,
        lookUpProducts: LookUpProductsUseCase,
        viewProduct: ViewProductUseCase,
        browseCategories: BrowseCategoriesUseCase
    ) {
        self.browseCatalog = browseCatalog
        self.lookUpProducts = lookUpProducts
        self.viewProduct = viewProduct
        self.browseCategories = browseCategories
    }

    init(_ productDI: ProductDI) {
        self.init(
            browseCatalog: productDI.browseCatalogUseCase,
            lookUpProducts: productDI.lookUpProductsUseCase,
            viewProduct: productDI.viewProductUseCase,
            browseCategories: productDI.browseCategoriesUseCase
        )
    }

    /// The real shop.
    static func live() -> Catalog {
        Catalog(ProductDI(client: DummyJSONProductClient(httpClient: URLSessionHTTPClient(session: .shared))))
    }
}
