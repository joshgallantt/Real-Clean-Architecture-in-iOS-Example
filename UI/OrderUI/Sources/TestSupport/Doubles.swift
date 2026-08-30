// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Foundation
import Bag
import Money
import Order
import Product
import AuthUI
import SnackbarUI
@testable import OrderUI

@MainActor
func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
}

@MainActor
extension BuyNowButtonViewModel {
    func tapAndSettle() async {
        didTap()
        await settle()
    }

    func settle() async {
        await yieldUntil { self.isPlacing }
        await yieldUntil { !self.isPlacing }
    }
}

@MainActor
extension CheckoutButtonViewModel {
    func tapAndSettle() async {
        didTap()
        await yieldUntil { self.isPlacing }
        await yieldUntil { !self.isPlacing }
    }
}

// MARK: - Fixtures

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

