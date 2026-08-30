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

    /// Waits for the work the tap started, and nothing else. Watching `isPlacing`
    /// go true and then false again yielded until the flag happened to agree,
    /// which is a guess about how busy the machine is rather than a wait.
    func settle() async {
        await inFlight?.value
    }
}
