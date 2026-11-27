import Foundation
import Money
import Tracking

/// What an event's items add up to: each product's price times how many. Nothing when anything is
/// not a product, or when the prices are in two currencies and could not be added without inventing
/// a rate — every vendor would rather have no value than a wrong one.
struct Worth {
    let amount: Decimal
    let currency: String

    init?(of items: [TrackedItem]) {
        let lines = items.compactMap { item -> (amount: Decimal, currency: String)? in
            guard case .product(_, let price, let quantity) = item.details else { return nil }
            return (price.amount * Decimal(quantity), price.currency.code)
        }
        guard !lines.isEmpty, lines.count == items.count, let currency = lines.first?.currency,
              lines.allSatisfy({ $0.currency == currency }) else {
            return nil
        }
        self.amount = lines.reduce(Decimal(0)) { $0 + $1.amount }
        self.currency = currency
    }
}
