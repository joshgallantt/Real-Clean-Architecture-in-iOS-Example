import ProductTestSupport
import SnackbarUITestSupport
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import StockAlert
@testable import WishlistUI

extension User {
    static func fixture() -> User {
        User(id: UserID(rawValue: 1), email: Email("ada@example.com"), name: PersonName(first: "Ada", last: nil))
    }
}
