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

    private var hasLoadedSuccessfully = false

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
        guard !hasLoadedSuccessfully else { return }
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        switch await browseCategories() {
        case .failure:
            showRetrySnackbar()
        case .success(let categories) where categories.isEmpty:
            carousels = []
            isEmpty = true
            hasLoadedSuccessfully = true
        case .success(let categories):
            isEmpty = false
            await loadCarousels(for: Array(categories.shuffled().prefix(maxCarousels)))
        }
    }

    private func loadCarousels(for categories: [ProductCategory]) async {
        var loaded: [HomeCarousel] = []
        var failures = 0

        for category in categories {
            let query = CatalogQuery(filter: .category(category), page: 0, pageSize: carouselCap)
            switch await browseCatalog(matching: query) {
            case .success(let products):
                let shown = Array(products.prefix(carouselCap))
                if shown.count >= carouselFloor {
                    loaded.append(HomeCarousel(category: category, products: shown))
                }
            case .failure:
                failures += 1
            }
        }

        guard failures < categories.count else {
            carousels = []
            showRetrySnackbar()
            return
        }

        carousels = loaded
        hasLoadedSuccessfully = true
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
