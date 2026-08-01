import Combine
import Foundation
import Product
import StockAlert
import AuthUI
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
///
/// The same shape as the wishlist heart, for the same reason: asking to be told needs an account,
/// so `.unauthenticated` is an answer the shopper gets back from what they tried, and the prompt
/// resumes what they were after rather than gating it first.
///
/// One use case with a state, rather than one for asking and another for stopping. Two use cases
/// meant this had to read its own `isWaiting` to decide which to call — a toggle re-derived from
/// the thing it was toggling.
public final class StockAlertButtonViewModel: ObservableObject {
    @Published private(set) var isWaiting = false

    private let productId: ProductID
    private let setStockAlert: SetStockAlertForProductUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: ProductID,
        observeWaitlistStatus: ObserveWaitlistStatusUseCase,
        setStockAlert: SetStockAlertForProductUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productId = productId
        self.setStockAlert = setStockAlert
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter

        observeWaitlistStatus(productId: productId)
            .sink { [weak self] value in
                self?.isWaiting = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        set(isOn: !isWaiting)
    }

    /// Taking it off the list, whatever the bell happens to say. A minus on a waitlist card means
    /// one thing, and it must not become "put it back" because the state arrived late.
    func didTapRemove() {
        set(isOn: false)
    }

    private func set(isOn: Bool) {
        Task { [weak self] in await self?.apply(isOn: isOn) }
    }

    private func apply(isOn: Bool) async {
        switch await setStockAlert(productId: productId, isOn: isOn) {
        case .success:
            snackbarPresenter.show(told(isOn))

        case .failure(.unauthenticated):
            guard await authPresenter.show(prompt(isOn)) else { return }
            await apply(isOn: isOn)

        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: isOn ? "Couldn't Set a Reminder" : "Couldn't Change That",
                message: "That didn't stick. Try again?",
                icon: "bell.slash",
                action: .retry { Task { await self.apply(isOn: isOn) } }
            ))
        }
    }

    private func told(_ isOn: Bool) -> Snackbar {
        isOn
            ? Snackbar(
                title: "You're on the List",
                message: "We'll tell you the second it's back.",
                icon: "bell.fill"
            )
            : Snackbar(
                title: "Off the List",
                message: "We'll keep quiet about this one.",
                icon: "bell.slash"
            )
    }

    private func prompt(_ isOn: Bool) -> AuthenticationPrompt {
        isOn
            ? AuthenticationPrompt(
                title: "Want to Know When It's Back?",
                message: "Sign in and we'll tell you.",
                icon: "bell.fill"
            )
            : AuthenticationPrompt(
                title: "Your Waitlist",
                message: "Sign in to change what we tell you about.",
                icon: "bell.slash"
            )
    }
}
