import Money
import MoneyTestSupport
import Order
import Product
import ProductTestSupport

extension Order {
    public static func fixture(lines: [OrderLine]? = nil) -> Order {
        Order(
            lines: lines ?? [OrderLine(productId: pid(1), pricePaid: usd(9.99))],
            paymentReference: PaymentReference(rawValue: "ref")
        )
    }
}
