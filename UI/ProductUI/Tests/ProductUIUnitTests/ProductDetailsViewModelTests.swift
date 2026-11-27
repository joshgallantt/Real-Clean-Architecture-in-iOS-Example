import Foundation
import ProductTestSupport
import Testing
import Tracking
import TrackingTestSupport
import TrackingUI
import Product
@testable import ProductUI

@MainActor
@Suite("Product details")
struct ProductDetailsViewModelTests {
    @Test("The screen is about the product it was handed, and nothing has to happen for that")
    /// There is one way to build this and it takes the product itself, so there is no appearing,
    /// no loading and no not-found — see `ProductDetailsViewModel`. What used to be tested here was
    /// three states of a lookup that no route can reach any more.
    func isAboutTheProductItWasHanded() {
        let viewModel = ProductDetailsViewModel(
            product: .fixture(id: 1),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )

        #expect(viewModel.product == .fixture(id: 1))
    }

    @Test("Coming into view reports the page, and the product on it as viewed, each time")
    func appearingReportsThePageAndTheProduct() {
        let screens = SpyTrackScreenViewUseCase()
        let reported = SpyTrackEventUseCase()
        let product = Product.fixture(id: 7)
        let viewModel = ProductDetailsViewModel(product: product, trackScreenView: screens, trackEvent: reported)
        let page = TrackingContext.screen("product_details")

        viewModel.didAppear(in: page)
        viewModel.didAppear(in: page)

        #expect(screens.events == Array(repeating: TrackingEvent(name: .screenViewed, context: .screen("product_details"), items: [], properties: [:]), count: 2))
        #expect(reported.events == Array(
            repeating: TrackingEvent(name: .productViewed, context: page, items: [TrackedProduct.item(product)], properties: [:]),
            count: 2
        ))
    }
}
