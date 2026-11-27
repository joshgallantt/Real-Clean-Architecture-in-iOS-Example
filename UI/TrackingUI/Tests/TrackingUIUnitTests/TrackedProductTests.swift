import Foundation
import Testing
import Money
import Product
import ProductTestSupport
import Tracking
import TrackingUI

@Suite("How a product is reported")
struct TrackedProductTests {
    @Test("One of a product, at the price on its label")
    func atItsLabel() {
        #expect(TrackedProduct.item(Product.fixture(id: 42, price: 19.99, category: "fragrances")) == .product(
            id: "42", name: "Product 42", category: "fragrances",
            price: Money(amount: 19.99, currency: .usd), quantity: 1
        ))
    }

    @Test("At a price the shopper agreed to, and as many as the event is about")
    func atAnAgreedPrice() {
        let item = TrackedProduct.item(Product.fixture(id: 1, price: 12), price: Money(amount: 9.99, currency: .usd), quantity: 3)

        #expect(item.details == .product(category: "beauty", price: Money(amount: 9.99, currency: .usd), quantity: 3))
    }
}
