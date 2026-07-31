import Foundation
import Money
import Order
import Product
import AuthUI
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class BuyNowButtonViewModel: ObservableObject {
    @Published private(set) var isPlacing = false

    private let product: Product
    private let placeOrder: PlaceOrderUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let confirm: (Order) -> Void

    public init(
        product: Product,
        placeOrder: PlaceOrderUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        confirm: @escaping (Order) -> Void
    ) {
        self.product = product
        self.placeOrder = placeOrder
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.confirm = confirm
    }

    var priceLabel: String { product.price.formatted() }

    /// The guard against a second tap lives here rather than in `buy`, because `buy` calls itself
    /// after a shopper signs in. A guard inside it would treat that resumed order as the double tap
    /// it exists to stop, and the shopper would sign in to nothing happening.
    func didTap() {
        guard !isPlacing else { return }
        Task {
            isPlacing = true
            defer { isPlacing = false }
            await buy()
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring turning what the catalog knows into what the order use case wants. One of this product,
    /// at the price the shopper is looking at — Buy Now never touches the bag, which is the whole
    /// difference between it and checking out.
    private var whatTheyAreBuying: [OrderLine] {
        [OrderLine(productId: product.id, quantity: 1, pricePaid: product.price)]
    }

    private func buy() async {
        switch await placeOrder(whatTheyAreBuying) {
        case .success(let order):
            confirm(order)

        /// The same move the wishlist heart makes: ask at the moment it is actually needed, and
        /// carry on if they signed in. A shopper who backs out is left where they were.
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Sign In to Buy",
                message: "Log in or create an account so we know where to send it.",
                icon: "bag.fill"
            )) else {
                return
            }
            await buy()

        case .failure(.paymentDeclined):
            snackbarPresenter.show(Snackbar(
                title: "Payment Declined",
                message: "That payment didn't go through. Try another way to pay.",
                icon: "creditcard.trianglebadge.exclamationmark"
            ))

        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "Couldn't Complete Your Order",
                message: "We couldn't reach the till just now.",
                icon: "exclamationmark.triangle",
                action: .retry { self.didTap() }
            ))

        /// A product page always has exactly one thing to buy, so this cannot happen from here. It
        /// is not silently ignored, because a button that quietly does nothing is the hardest kind
        /// of bug to notice.
        case .failure(.nothingToOrder):
            snackbarPresenter.show(Snackbar(
                title: "Nothing to Buy",
                message: "There was nothing in this order.",
                icon: "exclamationmark.triangle"
            ))
        }
    }
}
