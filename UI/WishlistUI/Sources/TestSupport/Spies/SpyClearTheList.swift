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
final class SpyClearTheList {
    private(set) var calls: [[ProductID]] = []

    func callAsFunction(_ ids: [ProductID]) async {
        calls.append(ids)
    }
}
