import Testing
import Product
import ProductTestSupport
import Tracking
import TrackingTestSupport
import TrackingUI
@testable import ProductUI

@MainActor
@Suite("What a product card reports, wherever it is drawn")
struct ProductCardTrackingTests {
    private let carousel = TrackingContext.list("home", TrackingContext.List(id: "home_carousel_beauty", name: "Beauty"), index: 4)

    @Test("A card seen is an impression of its product, where the card was")
    func seen() {
        let elements = SpyTrackElementViewUseCase()

        ProductCardTracking(trackElementView: elements, trackElementInteraction: SpyTrackElementInteractionUseCase()).seen(.fixture(id: 7), in: carousel)

        #expect(elements.events == [TrackingEvent(name: .elementViewed, context: carousel, items: [TrackedProduct.item(.fixture(id: 7))], properties: ["element": "product"])])
    }

    @Test("A card tapped is a tap on its product, where the card was")
    func selected() {
        let elements = SpyTrackElementInteractionUseCase()

        ProductCardTracking(trackElementView: SpyTrackElementViewUseCase(), trackElementInteraction: elements).selected(.fixture(id: 7), in: carousel)

        #expect(elements.events == [TrackingEvent(name: .elementSelected, context: carousel, items: [TrackedProduct.item(.fixture(id: 7))], properties: ["element": "product"])])
    }
}
