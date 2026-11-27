import Combine
import Foundation
import Product
import Wishlist
import AuthUI
import SnackbarUI
import Tracking
import TrackingUI

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
///
/// One use case with a state, rather than one for saving and another for unsaving. Two use cases
/// meant this had to read its own `isInWishlist` to decide which to call — a toggle re-derived from
/// the thing it was toggling.
public final class WishlistButtonViewModel {
    private(set) var isInWishlist = false

    private let product: Product
    private let observeProductIsWishlisted: ObserveProductIsWishlistedUseCase
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase
    private var cancellables = Set<AnyCancellable>()
    /// The work the last tap started. Public so a test can wait for exactly
    /// that, and so the screen could cancel it on disappear.
    public private(set) var inFlight: Task<Void, Never>?

    public init(
        product: Product,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.product = product
        self.observeProductIsWishlisted = observeProductIsWishlisted
        self.setProductIsWishlisted = setProductIsWishlisted
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// Subscribing happens here rather than in `init`.
    ///
    /// `@State` evaluates its initial value every time SwiftUI initialises the
    /// view — Apple's guidance is to "avoid side effects and performance-intensive
    /// work when initializing the default value" — and this button is built once
    /// per product card. A subscription in `init` would therefore run on every
    /// card of every render, on instances SwiftUI then throws away.
    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeProductIsWishlisted(productId: product.id)
            .sink { [weak self] value in
                self?.isInWishlist = value
            }
            .store(in: &cancellables)
    }

    /// Which way a tap goes is read from `isInWishlist`, and that only changes once the save has
    /// been kept and published. Deciding at the moment of the tap meant a second tap read the state
    /// the first one had set out to change, so tapping on and straight off again left it on. The
    /// decision is made inside the queued work instead, once the tap before it has settled.
    ///
    /// The tap is tracked there too, and once: which way it goes is only known inside the queue,
    /// and signing in part-way and carrying on is still the one tap. The save is tracked only once
    /// it has been kept, because a heart that did not stick is not a product saved.
    ///
    /// `context` is where the heart is drawn — a card's position in a carousel, or the product page —
    /// as the view read it. The heart itself never knows which screen it is on.
    func didTap(in context: TrackingContext) {
        enqueue { [weak self] in
            guard let self else { return }
            let isWishlisted = !self.isInWishlist
            self.trackElementInteraction(ProductActionsTrackingPlan.wishlist(isOn: isWishlisted), about: self.item, in: context)
            await self.apply(isWishlisted: isWishlisted, in: context)
        }
    }

    /// What every event from this heart is about.
    private var item: TrackedItem { TrackedProduct.item(product) }

    /// The product saved, which is what a report counts. The tap before it was only the attempt.
    private func saved(in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(name: .productAddedToWishlist, context: context, items: [item], properties: [:])
    }

    /// Every snackbar this heart shows is seen, which is what makes a tap on its action a rate.
    private func show(_ snackbar: Snackbar, in context: TrackingContext) {
        trackElementView(snackbar.trackingName, about: item, in: context)
        snackbarPresenter.show(snackbar)
    }

    /// One tap at a time, in the order the shopper made them, so two taps are two decisions rather
    /// than the same decision twice.
    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = inFlight
        inFlight = Task {
            await previous?.value
            await work()
        }
    }

    private func apply(isWishlisted: Bool, in context: TrackingContext) async {
        switch await setProductIsWishlisted(productId: product.id, isWishlisted: isWishlisted) {
        case .success:
            if isWishlisted { trackEvent(saved(in: context)) }
            show(told(isWishlisted), in: context)

        case .failure(.unauthenticated):
            let signedIn = await authPresenter.show(prompt(isWishlisted))
            /// The sheet covered the screen; closing it does not make the screen appear again, so it
            /// is said here — by the one thing that knows a sheet was in the way.
            trackScreenView(context.screen)
            guard signedIn else { return }
            await apply(isWishlisted: isWishlisted, in: context)

        case .failure(.unavailable):
            show(Snackbar(
                title: isWishlisted ? "Didn't Save" : "Didn't Change",
                message: "That didn't stick. Try again?",
                icon: "heart.slash",
                action: .retry { Task { await self.apply(isWishlisted: isWishlisted, in: context) } }
            ), in: context)
        }
    }

    private func told(_ isWishlisted: Bool) -> Snackbar {
        isWishlisted
            ? Snackbar(
                title: "Saved",
                message: "It's in your faves.",
                icon: "heart.fill"
            )
            : Snackbar(
                title: "Unsaved",
                message: "Gone from your faves.",
                icon: "heart.slash"
            )
    }

    private func prompt(_ isWishlisted: Bool) -> AuthenticationPrompt {
        isWishlisted
            ? AuthenticationPrompt(
                title: "Keep Your Faves",
                message: "Sign in and everything you save sticks around.",
                icon: "heart.fill"
            )
            : AuthenticationPrompt(
                title: "Your Faves",
                message: "Sign in to change what you've saved.",
                icon: "heart.slash"
            )
    }
}
