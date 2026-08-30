import AsyncTesting
import ProductTestSupport
import SnackbarUITestSupport
import Bag
import Money
import Order
import Product
import AuthUI
import SnackbarUI
@testable import OrderUI

@MainActor
extension CheckoutButtonViewModel {
    func tapAndSettle() async {
        didTap()
        await yieldUntil { self.isPlacing }
        await yieldUntil { !self.isPlacing }
    }
}
