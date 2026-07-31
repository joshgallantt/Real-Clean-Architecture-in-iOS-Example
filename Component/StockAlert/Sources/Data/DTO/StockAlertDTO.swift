import Foundation
import Product
import StockAlert

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
struct StockAlertDTO: Codable, Sendable {
    let productId: Int
    let dateAsked: Date


    init(from alert: StockAlert) {
        self.productId = alert.productId.rawValue
        self.dateAsked = alert.dateAsked
    }

    func toDomain() -> StockAlert {
        StockAlert(productId: ProductID(rawValue: productId), dateAsked: dateAsked)
    }
}
