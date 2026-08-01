import Combine
import Foundation
import Product

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class HomeScreenViewModel: ObservableObject {
    @Published private(set) var state: HomeScreenState = .loading

    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase
    private let navigation: HomeNavigation

    private let maxCarousels = 3
    private let carouselFloor = 5
    private let carouselCap = 10

    public init(
        browseCatalog: BrowseCatalogUseCase,
        browseCategories: BrowseCategoriesUseCase,
        navigation: HomeNavigation
    ) {
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
        self.navigation = navigation
    }

    func onAppear() async {
        if case .loaded = state { return }
        await load()
    }

    func didTapRetry() {
        Task { await load() }
    }

    /// Evans, Ch. 10 — Supple Design, Side-Effect-Free Functions: "keep the commands and queries
    /// strictly segregated in different operations." Asking the shop is a query answering with a
    /// `HomeScreenState`; `load()` is the one command that moves what a shopper sees.
    private func load() async {
        state = .loading

        state = await drawFeed()
    }

    private func drawFeed() async -> HomeScreenState {
        switch await browseCategories() {
        case .failure:
            return .error
        case .success(let categories):
            return await drawCarousels(for: Array(categories.shuffled().prefix(maxCarousels)))
        }
    }

    /// A category that fails is simply absent, the same as one that never earned a carousel — so
    /// the shop being unreachable needs no counting of its own: nothing drawn is `.error`.
    private func drawCarousels(for categories: [ProductCategory]) async -> HomeScreenState {
        var drawn: [HomeCarousel] = []

        for category in categories {
            let query = CatalogQuery(filter: .category(category), page: 0, pageSize: carouselCap)
            if case .success(let products) = await browseCatalog(matching: query) {
                let shown = Array(products.prefix(carouselCap))
                if shown.count >= carouselFloor {
                    drawn.append(HomeCarousel(category: category, products: shown))
                }
            }
        }

        guard let feed = HomeFeed(carousels: drawn) else { return .error }
        return .loaded(feed)
    }

    func didSelect(_ product: Product) {
        navigation.openProductDetails(product: product)
    }

    func didTapViewAll(for carousel: HomeCarousel) {
        navigation.openCatalog(filter: .category(carousel.category))
    }
}
