import Foundation
import Product
import StockAlert

/// The shape stock alerts were first written in, under `StockAlerts/`. Read once, to carry a
/// shopper's alerts forward into the shape `StockAlertDTO` keeps, and never written.
struct LegacyStockAlertDTO: Decodable, Sendable {
    let productId: Int
    let dateAsked: Date

    func toDomain() -> StockAlert {
        StockAlert(productId: ProductID(rawValue: productId), dateAdded: dateAsked)
    }
}
