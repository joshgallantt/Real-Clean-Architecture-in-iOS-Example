import Combine
import Foundation
import Product
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class HomeScreenViewModel: ObservableObject {
    @Published private(set) var carousels: [HomeCarousel] = []
    @Published private(set) var isLoading = false

    /// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: a shop with
    /// nothing to organise into categories is its own state, not the same emptiness a failed load
    /// leaves behind.
    @Published private(set) var isEmpty = false

    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase
    private let navigation: HomeNavigation
    private let snackbar: SnackbarPresenting

    private var hasDrawnTheFeed = false

    private let maxCarousels = 3
    private let carouselFloor = 5
    private let carouselCap = 10

    public init(
        browseCatalog: BrowseCatalogUseCase,
        browseCategories: BrowseCategoriesUseCase,
        navigation: HomeNavigation,
        snackbar: SnackbarPresenting
    ) {
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
        self.navigation = navigation
        self.snackbar = snackbar
    }

    func onAppear() async {
        guard !hasDrawnTheFeed else { return }
        await load()
    }

    /// Evans, Ch. 10 — Supple Design, Side-Effect-Free Functions: "keep the commands and queries
    /// strictly segregated in different operations." Asking the shop is a query answering with a
    /// `FeedDraw`; `show(_:)` is the one command that moves what a shopper sees.
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        show(await drawFeed())
    }

    private func drawFeed() async -> FeedDraw {
        switch await browseCategories() {
        case .failure:
            return .unreachable
        case .success(let categories) where categories.isEmpty:
            return .nothingToOrganise
        case .success(let categories):
            return await drawCarousels(for: Array(categories.shuffled().prefix(maxCarousels)))
        }
    }

    private func drawCarousels(for categories: [ProductCategory]) async -> FeedDraw {
        var drawn: [HomeCarousel] = []
        var failures = 0

        for category in categories {
            let query = CatalogQuery(filter: .category(category), page: 0, pageSize: carouselCap)
            switch await browseCatalog(matching: query) {
            case .success(let products):
                let shown = Array(products.prefix(carouselCap))
                if shown.count >= carouselFloor {
                    drawn.append(HomeCarousel(category: category, products: shown))
                }
            case .failure:
                failures += 1
            }
        }

        return failures < categories.count ? .carousels(drawn) : .unreachable
    }

    private func show(_ draw: FeedDraw) {
        switch draw {
        case .unreachable:
            carousels = []
            showRetrySnackbar()
        case .nothingToOrganise:
            carousels = []
            isEmpty = true
            hasDrawnTheFeed = true
        case .carousels(let drawn):
            carousels = drawn
            isEmpty = false
            hasDrawnTheFeed = true
        }
    }

    private func showRetrySnackbar() {
        snackbar.show(Snackbar(
            title: "Nothing's Loading",
            message: "Check your signal and give it another go.",
            icon: "wifi.exclamationmark",
            action: .retry { [weak self] in
                Task { await self?.load() }
            }
        ))
    }

    func didSelect(_ product: Product) {
        navigation.openProductDetails(product: product)
    }

    func didTapViewAll(for carousel: HomeCarousel) {
        navigation.openCatalog(filter: .category(carousel.category))
    }
}

/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what one attempt
/// at the feed came back with. A shop that cannot be reached, a shop with nothing to organise into
/// categories, and the carousels the shop's categories earned are three outcomes, not three
/// arrangements of the same fields.
private enum FeedDraw {
    case unreachable
    case nothingToOrganise
    case carousels([HomeCarousel])
}
