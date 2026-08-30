import Combine
import Foundation
import Order

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// It reads one use case and nothing else. Notably it never touches the catalog: an order records
/// what was paid, so history renders in full for products the shop has since withdrawn — which is
/// exactly the case a screen built on product lookups would get wrong.
public final class OrderHistoryViewModel {
    private(set) var orders: [OrderSummary] = []

    private let observeOrders: ObserveOrdersUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(observeOrders: ObserveOrdersUseCase) {
        self.observeOrders = observeOrders
    }

    /// Subscribing happens here rather than in `init`, because `@State` builds its
    /// initial value on every view initialisation and a subscription is a side
    /// effect Apple's guidance says to keep out of that.
    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeOrders()
            .sink { [weak self] orders in
                self?.orders = orders.all.map(OrderSummary.init)
            }
            .store(in: &cancellables)
    }

    var isEmpty: Bool { orders.isEmpty }
}
