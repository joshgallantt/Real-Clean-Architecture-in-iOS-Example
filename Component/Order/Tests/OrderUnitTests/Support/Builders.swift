import Foundation
import Money
import MoneyTestSupport
import ProductTestSupport
@testable import Order

func line(_ id: Int, quantity: Int = 1, at price: Decimal) -> OrderLine {
    OrderLine(productId: pid(id), quantity: quantity, pricePaid: usd(price))
}

func order(_ lines: [OrderLine], at placed: Date = Date()) -> Order {
    Order(lines: lines, placedAt: placed, paymentReference: PaymentReference(rawValue: "ref"))
}
