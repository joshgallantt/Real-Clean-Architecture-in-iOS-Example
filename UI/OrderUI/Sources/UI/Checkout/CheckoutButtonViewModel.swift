import Combine
import Foundation
import Bag
import Money
import Order
import Product
import AuthUI
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 13 — Component Cohesion: this lives in `OrderUI` rather than `BagUI` because it
/// changes when ordering changes, not when the bag does. `BagUI` is handed a finished button and
/// never learns there is an order domain, the same way it is handed a stock alert bell.
public final class CheckoutButtonViewModel: ObservableObject {
    @Published private(set) var isPlacing = false
    @Published private(set) var bag = Bag()

    private let placeOrder: PlaceOrderUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let confirm: (Order) -> Void
    private var cancellables = Set<AnyCancellable>()

    public init(
        observeBag: ObserveBagUseCase,
        placeOrder: PlaceOrderUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        confirm: @escaping (Order) -> Void
    ) {
        self.placeOrder = placeOrder
        self.setBagItemQuantity = setBagItemQuantity
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.confirm = confirm

        observeBag()
            .sink { [weak self] bag in
                self?.bag = bag
            }
            .store(in: &cancellables)
    }

    var isEmpty: Bool { bag.isEmpty }

    var totalLabel: String { bag.total?.formatted() ?? "" }

    /// The guard against a second tap lives here rather than in `checkOut`, because `checkOut` calls
    /// itself after a shopper signs in. A guard inside it would treat that resumed order as the
    /// double tap it exists to stop, and the shopper would sign in to nothing happening.
    func didTap() {
        guard !isPlacing else { return }
        Task {
            isPlacing = true
            defer { isPlacing = false }
            await checkOut()
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring, converting what a bag holds into what an order is made of. The price a shopper is
    /// charged is the one their bag was showing them, which `BringBagUpToDateUseCase` has already
    /// brought level with the shop.
    private var whatTheyAreBuying: [OrderLine] {
        bag.items.map {
            OrderLine(productId: $0.productId, quantity: $0.quantity, pricePaid: $0.lastKnownPrice)
        }
    }

    private func checkOut() async {
        switch await placeOrder(whatTheyAreBuying) {
        case .success(let order):
            emptyTheBag()
            confirm(order)

        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Almost Yours",
                message: "Sign in so we know where to send it.",
                icon: "bag.fill"
            )) else {
                return
            }
            await checkOut()

        case .failure(.paymentDeclined):
            snackbarPresenter.show(Snackbar(
                title: "Payment Declined",
                message: "That card didn't go through. Your bag's still here.",
                icon: "creditcard.trianglebadge.exclamationmark"
            ))

        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "That Didn't Go Through",
                message: "Our end, not yours. Your bag's still here.",
                icon: "exclamationmark.triangle",
                action: .retry { self.didTap() }
            ))

        case .failure(.nothingToOrder):
            snackbarPresenter.show(Snackbar(
                title: "Nothing in Your Bag",
                message: "Add something first.",
                icon: "bag"
            ))
        }
    }

    /// Only once the order exists. A bag emptied before the payment went through would leave a
    /// shopper with neither, which is the worst of the three outcomes and the easiest to cause.
    ///
    /// Every line goes the way a single swipe sends one, so there is no second path through the
    /// domain to keep in step with the first.
    private func emptyTheBag() {
        for item in bag.items {
            setBagItemQuantity(productId: item.productId, to: 0)
        }
    }
}
