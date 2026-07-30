import Combine
import Foundation
import Product
import SnackbarUI

@MainActor
public final class HomeScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private let browseCatalog: BrowseCatalogUseCase
    private let snackbar: SnackbarPresenting

    public init(browseCatalog: BrowseCatalogUseCase, snackbar: SnackbarPresenting) {
        self.browseCatalog = browseCatalog
        self.snackbar = snackbar
    }

    func onAppear() async {
        guard products.isEmpty else { return }
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        switch await browseCatalog(matching: .all(page: 0, pageSize: 30)) {
        case .success(let value):
            products = value
        case .failure:
            snackbar.show(Snackbar(
                title: "Couldn't Load Products",
                message: "Check your connection and try again.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    Task { await self?.load() }
                }
            ))
        }
    }

    func didSelect(_ product: Product) {
        // Any non-navigation side effects, e.g. analytics
    }
}
