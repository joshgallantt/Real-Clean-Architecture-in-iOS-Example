import ProductTestSupport
import SnackbarUITestSupport
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import StockAlert
@testable import WishlistUI

@MainActor
final class SpyGetAlertedProducts {
    var result: Result<[Product], StockAlertError> = .success([])
    private(set) var callCount = 0

    func callAsFunction() async -> Result<[Product], StockAlertError> {
        callCount += 1
        return result
    }
}
