import Foundation
import Money
import Product
import Home
import HomeDI
import ProductTestSupport

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A test says
/// what a shopper's Home drew, never which type stored it or how it chose it.
///
/// Only one thing is genuinely faked — `Shop`, standing in for `ProductRepository`. Everything
/// between it and the draw is real: `DefaultBrowseCatalogUseCase`, `DefaultBrowseCategoriesUseCase`
/// and `HomeDI`'s own use case.
final class Shopper {
    let shop = Shop()
    private let di: HomeDI

    init() {
        di = HomeDI(
            browseCatalog: DefaultBrowseCatalogUseCase(productRepository: shop),
            browseCategories: DefaultBrowseCategoriesUseCase(productRepository: shop)
        )
    }

    // MARK: - What the shop sells

    func sells(_ category: ProductCategory, _ products: [Product]) {
        shop.sell(category, products)
    }

    // MARK: - What a shopper does

    private var feed: HomeFeed?
    private(set) var homeCouldNotBeDrawn = false

    @discardableResult
    func opensHome() async -> Shopper {
        switch await di.drawHomeFeedUseCase() {
        case .success(let feed):
            self.feed = feed
            homeCouldNotBeDrawn = false
        case .failure:
            self.feed = nil
            homeCouldNotBeDrawn = true
        }
        return self
    }

    // MARK: - What a shopper sees

    var carouselsShown: [HomeCarousel] { feed?.carousels ?? [] }
}
