import Combine
import Foundation
import Order

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// It reads one use case and nothing else. Notably it never touches the catalog: an order records
/// what was paid, so history renders in full for products the shop has since withdrawn — which is
/// exactly the case a screen built on product lookups would get wrong.
public final class OrderHistoryViewModel: ObservableObject {
    @Published private(set) var orders: [OrderSummary] = []

    private var cancellables = Set<AnyCancellable>()

    public init(observeOrders: ObserveOrdersUseCase) {
        observeOrders()
            .sink { [weak self] orders in
                self?.orders = orders.all.map(OrderSummary.init)
            }
            .store(in: &cancellables)
    }

    var isEmpty: Bool { orders.isEmpty }
}
