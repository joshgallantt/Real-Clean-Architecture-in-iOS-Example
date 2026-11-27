import Foundation
import Order
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the confirmation
/// has nothing to load and nothing that can fail, but it has a screen to report and a Done to
/// count. Those are behaviour, so they live here rather than in the view.
public final class OrderConfirmationViewModel {
    let order: OrderSummary

    private let done: () -> Void
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        order: OrderSummary,
        done: @escaping () -> Void,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.order = order
        self.done = done
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func didTapDone(in context: TrackingContext) {
        trackElementInteraction(OrderTrackingPlan.done, in: context)
        done()
    }
}
