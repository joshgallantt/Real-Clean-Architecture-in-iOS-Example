import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Order

@Suite("Failing to order")
struct OrderErrorTests {
    @Test("A decline is not the same failure as being unable to reach anybody")
    func declineIsDistinct() {
        #expect(OrderError.paymentDeclined != OrderError.unavailable)
    }

    @Test("Being signed out is its own failure")
    func unauthenticatedIsDistinct() {
        #expect(OrderError.unauthenticated != OrderError.paymentDeclined)
    }

    @Test("Having nothing to buy is its own failure, not a silent success")
    func nothingToOrderIsDistinct() {
        #expect(OrderError.nothingToOrder != OrderError.unavailable)
    }

    @Test("A payment failure is told apart the same way")
    func paymentFailures() {
        #expect(PaymentFailure.declined != PaymentFailure.unavailable)
    }
}
