import Foundation
import ProductTestSupport
import Testing
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
        let viewModel = ProductDetailsViewModel(product: .fixture(id: 1))

        #expect(viewModel.product == .fixture(id: 1))
    }
}
