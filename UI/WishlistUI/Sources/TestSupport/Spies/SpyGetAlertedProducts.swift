import ProductTestSupport
import SnackbarUITestSupport
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import Waitlist
@testable import WishlistUI

@MainActor
final class SpyGetAlertedProducts {
    var result: Result<[Product], WaitlistError> = .success([])
    private(set) var callCount = 0

    func callAsFunction() async -> Result<[Product], WaitlistError> {
        callCount += 1
        return result
    }
}
