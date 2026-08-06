import Product

/// Evans, Ch. 2 — Ubiquitous Language: the user's own words for this rule — "pick random categories
/// until 5 can be shown".
public struct DefaultDrawHomeFeedUseCase: DrawHomeFeedUseCase {
    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase

    private let carouselFloor = 5
    private let carouselCap = 10
    private let maxCarousels = 5

    public init(browseCatalog: BrowseCatalogUseCase, browseCategories: BrowseCategoriesUseCase) {
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
    }

    public func callAsFunction() async -> Result<HomeFeed, HomeError> {
        guard case .success(let categories) = await browseCategories(), !categories.isEmpty else {
            return .failure(.unavailable)
        }

        var carousels: [HomeCarousel] = []
        for category in categories.shuffled() {
            guard carousels.count < maxCarousels else { break }
            guard let products = await qualifyingProducts(for: category) else { continue }
            carousels.append(HomeCarousel(category: category, products: products))
        }

        guard let feed = HomeFeed(carousels: carousels) else { return .failure(.unavailable) }
        return .success(feed)
    }

    private func qualifyingProducts(for category: ProductCategory) async -> [Product]? {
        let query = CatalogQuery(filter: .category(category), page: 0, pageSize: carouselCap)
        guard case .success(let products) = await browseCatalog(matching: query) else { return nil }
        let shown = Array(products.prefix(carouselCap))
        return shown.count >= carouselFloor ? shown : nil
    }
}
