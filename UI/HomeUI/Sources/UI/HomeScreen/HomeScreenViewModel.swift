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
                title: "Nothing's Loading",
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    Task { await self?.load() }
                }
            ))
        }
    }

    func didSelect(_ product: Product) {
    }
}
