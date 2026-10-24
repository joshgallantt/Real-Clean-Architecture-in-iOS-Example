import Foundation
import Product
import Waitlist

/// The shape the waitlist was written in when it was called stock alerts. Read once, to carry a
/// shopper's list forward, and never written.
struct LegacyStockAlertDTO: Decodable, Sendable {
    let productId: Int
    let dateAsked: Date

    func toDomain() -> WaitlistItem {
        WaitlistItem(productId: ProductID(rawValue: productId), dateAdded: dateAsked)
    }
}
