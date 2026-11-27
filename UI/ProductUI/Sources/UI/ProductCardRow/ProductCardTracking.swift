import Product
import Tracking
import TrackingUI

/// What every list of product cards reports, said once. Home's carousels, the search grid and the
/// wishlist rows are the same cards, so a card seen or tapped means the same thing on each — and a
/// screen that hosts them calls this rather than writing its own copy of the same two lines.
///
/// Not a view model: it holds nothing, and the list it reports on belongs to the screen that drew
/// it. Where the card was — which list, which position — arrives with the context the card read.
@MainActor
public struct ProductCardTracking {
    public static let card = "product"

    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(trackElementView: TrackElementViewUseCase, trackElementInteraction: TrackElementInteractionUseCase) {
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
    }

    public func seen(_ product: Product, in context: TrackingContext) {
        trackElementView(Self.card, about: TrackedProduct.item(product), in: context)
    }

    public func selected(_ product: Product, in context: TrackingContext) {
        trackElementInteraction(Self.card, about: TrackedProduct.item(product), in: context)
    }
}
