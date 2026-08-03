import Foundation
import Money

/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. The suite says
/// what a shopper was charged for and what they owe for it, never how an amount is held. Nothing
/// here names `minorUnits`; that is the unit tier's language, one floor down.
final class Till {
    private let currency: Currency
    private var rung: [Money] = []

    init(charging currency: Currency = .usd) {
        self.currency = currency
    }

    /// Puts a price through, however many of that thing the shopper is taking.
    func rings(_ price: Decimal, times count: Int = 1) {
        rung.append(Money(amount: price, currency: currency) * count)
    }

    /// What the shopper owes for everything rung up, or nothing at all if nothing was.
    var amountDue: Money? {
        Money.total(of: rung)
    }

    /// The price a shopper would recognise, for comparing against what they owe.
    func price(_ amount: Decimal) -> Money {
        Money(amount: amount, currency: currency)
    }
}
