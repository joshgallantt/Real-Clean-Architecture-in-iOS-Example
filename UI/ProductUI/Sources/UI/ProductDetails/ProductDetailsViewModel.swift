import Foundation
import Product
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
/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities: a product, not an id and a way of
/// turning it into one. Every route here carries the thing itself, so there is nothing to look up,
/// nothing to be waiting on and nothing to fail to find — three states that were representable and
/// only one of which ever happened.
public final class ProductDetailsViewModel {
    let product: Product

    private let trackScreenView: TrackScreenViewUseCase
    private let trackEvent: TrackEventUseCase

    public init(product: Product, trackScreenView: TrackScreenViewUseCase, trackEvent: TrackEventUseCase) {
        self.product = product
        self.trackScreenView = trackScreenView
        self.trackEvent = trackEvent
    }

    /// Every time the page comes into view — back from the bag counts as looking at it again —
    /// and the product with it, because a product page in view is the product being viewed.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
        trackEvent(TrackingEvent(name: .productViewed, context: context, items: [TrackedProduct.item(product)], properties: [:]))
    }
}
