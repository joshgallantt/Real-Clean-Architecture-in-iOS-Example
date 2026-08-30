import Combine
import Foundation
import Product
import SnackbarUI
import StockAlert

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: it calls one use
/// case and publishes what came back. Which products belong on this list is not decided here — it
/// is decided by which use case this was handed, and that is the whole point.
///
/// Martin, Ch. 10 — Interface Segregation Principle: `SavedProductsViewModel` fills in a list of
/// ids the shopper is holding, which is what a wishlist is. This does not: the domain already
/// answers with products, so there is nothing to fill in and no ids to page through.
public final class AlertedProductsViewModel {
    /// Carries the cancellation: a fresh load replaces the one before it.
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var products: [Product] = []
    private(set) var isLoading = false

    private let load: @MainActor () async -> Result<[Product], StockAlertError>
    private let changes: () -> AnyPublisher<StockAlerts, Never>
    private let clear: @MainActor ([ProductID]) async -> Void
    private let snackbar: SnackbarPresenting
    private let couldNotLoad: String

    private var cancellables = Set<AnyCancellable>()

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
    /// `async` so the list can await it from `.task`: SwiftUI then owns the load
    /// for as long as the row is on screen and cancels it on the way out. The two
    /// synchronous callers below — a change in what was asked, and the retry
    /// button — go through `startReloading()`, which is where the handle earns its
    /// keep.
    func onAppear() async {
        if cancellables.isEmpty {
            changes()
                .removeDuplicates()
                .sink { [weak self] _ in self?.startReloading() }
                .store(in: &cancellables)
        }

        await reload()
    }

    func didConfirmClear() {
        let losing = products.map(\.id)
        guard !losing.isEmpty else { return }
        inFlight = Task { await clear(losing) }
    }

    private func startReloading() {
        reloadTask?.cancel()
        isLoading = true

        let task = Task { [weak self] in
            guard let self else { return }
            await self.reload()
        }
        reloadTask = task
        inFlight = task
    }

    private func reload() async {
        isLoading = true

        let result = await load()
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let loaded):
            products = loaded

        /// The list is left as it was. A dropped connection is not evidence that a shopper has
        /// stopped waiting on anything, and emptying the row would say that it is.
        case .failure:
            snackbar.show(Snackbar(
                title: couldNotLoad,
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in self?.startReloading() }
            ))
        }

        isLoading = false
    }
}
