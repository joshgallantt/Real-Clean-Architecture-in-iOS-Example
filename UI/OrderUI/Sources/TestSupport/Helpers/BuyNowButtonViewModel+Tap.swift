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
