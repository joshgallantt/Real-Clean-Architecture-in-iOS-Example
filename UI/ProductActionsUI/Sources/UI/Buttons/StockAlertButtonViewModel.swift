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
public final class StockAlertButtonViewModel: ObservableObject {
    @Published private(set) var isWaiting = false

    private let productId: ProductID
    private let askToBeTold: AskToBeToldWhenBackUseCase
    private let stopBeingTold: StopBeingToldWhenBackUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: ProductID,
        observeWaitingForProduct: ObserveWaitingForProductUseCase,
        askToBeTold: AskToBeToldWhenBackUseCase,
        stopBeingTold: StopBeingToldWhenBackUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productId = productId
        self.askToBeTold = askToBeTold
        self.stopBeingTold = stopBeingTold
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter

        observeWaitingForProduct(productId: productId)
            .sink { [weak self] value in
                self?.isWaiting = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        Task { [weak self] in
            guard let self else { return }
            if self.isWaiting {
                await self.stopWaiting()
            } else {
                await self.ask()
            }
        }
    }

    private func ask() async {
        switch await askToBeTold(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "We'll Let You Know",
                message: "You'll hear from us when this is back in stock.",
                icon: "bell.fill"
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "We'll Tell You When It's Back",
                message: "Log in or create an account and we'll let you know.",
                icon: "bell.fill"
            )) else {
                return
            }
            await self.ask()
        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "Couldn't Set a Reminder",
                message: "We couldn't note that down just now.",
                icon: "bell.slash",
                action: .retry { Task { await self.ask() } }
            ))
        }
    }

    private func stopWaiting() async {
        switch await stopBeingTold(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "We Won't Let You Know",
                message: "You'll hear nothing more about this one.",
                icon: "bell.slash"
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Manage Your Reminders",
                message: "Log in or create an account to change what we tell you about.",
                icon: "bell.slash"
            )) else {
                return
            }
            await self.stopWaiting()
        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "Couldn't Change That",
                message: "We couldn't change that just now.",
                icon: "bell.slash",
                action: .retry { Task { await self.stopWaiting() } }
            ))
        }
    }
}
