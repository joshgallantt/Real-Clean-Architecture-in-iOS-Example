import Combine
import Foundation
import Product
import SnackbarUI
import StockAlert

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: it calls one use
/// case and publishes what came back. Which products belong on this list is not decided here — it
/// is decided by which use case this was handed, and that is the whole point.
///
/// Martin, Ch. 10 — Interface Segregation Principle: `SavedProductsViewModel` fills in a list of
/// ids the shopper is holding, which is what a wishlist is. This does not: the domain already
/// answers with products, so there is nothing to fill in and no ids to page through.
public final class AlertedProductsViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private let load: @MainActor () async -> Result<[Product], StockAlertError>
    private let changes: () -> AnyPublisher<StockAlerts, Never>
    private let clear: @MainActor ([ProductID]) async -> Void
    private let snackbar: SnackbarPresenting
    private let couldNotLoad: String

    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    public init(
        load: @escaping @MainActor () async -> Result<[Product], StockAlertError>,
        changes: @escaping () -> AnyPublisher<StockAlerts, Never>,
        clear: @escaping @MainActor ([ProductID]) async -> Void,
        snackbar: SnackbarPresenting,
        couldNotLoad: String
    ) {
        self.load = load
        self.changes = changes
        self.clear = clear
        self.snackbar = snackbar
        self.couldNotLoad = couldNotLoad
    }

    var isEmpty: Bool { products.isEmpty }

    var count: Int { products.count }

    /// The asks are watched, but only as a reason to ask again. What is *on* this list depends on
    /// what the shop stocks as well as what was asked, and only the use case knows both.
    func onAppear() {
        if cancellables.isEmpty {
            changes()
                .removeDuplicates()
                .sink { [weak self] _ in self?.reload() }
                .store(in: &cancellables)
        }

        reload()
    }

    func didConfirmClear() {
        let losing = products.map(\.id)
        guard !losing.isEmpty else { return }
        Task { await clear(losing) }
    }

    private func reload() {
        loadTask?.cancel()
        isLoading = true

        loadTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.load()
            guard !Task.isCancelled else { return }

            switch result {
            case .success(let products):
                self.products = products

            /// The list is left as it was. A dropped connection is not evidence that a shopper has
            /// stopped waiting on anything, and emptying the row would say that it is.
            case .failure:
                self.snackbar.show(Snackbar(
                    title: self.couldNotLoad,
                    message: "Check your connection and try again.",
                    icon: "wifi.exclamationmark",
                    action: .retry { [weak self] in self?.reload() }
                ))
            }

            self.isLoading = false
        }
    }
}
