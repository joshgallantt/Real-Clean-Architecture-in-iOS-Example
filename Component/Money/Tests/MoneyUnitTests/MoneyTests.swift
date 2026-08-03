import Foundation
import Testing
@testable import Money

@Suite("Amounts of money")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary. The unit tier, in the language
/// of the system: `minorUnits`, rounding modes and the boundaries either side of half a penny. What
/// a shopper notices about money — what a basket comes to — is stated as a journey in the
/// acceptance tier, and again where they would actually notice it, in the bag.
///
/// This suite once opened by arguing that `Money` was a `Library/` with no shopper of its own. It is
/// a domain component now: exact arithmetic and same-currency addition are business rules, not
/// utility guarantees, which is why the domain had to name `Money` by hand to reach it.
struct MoneyTests {
    // MARK: - Exactness, which is the whole reason this type exists

    @Test
    func addingPricesIsExact() {
        let total = Money.total(of: [
            Money(amount: 9.99, currency: .usd),
            Money(amount: 49.99, currency: .usd)
        ])

        #expect(total == Money(minorUnits: 5998, currency: .usd))
    }

    @Test
    func amountsThatShouldBeEqualAreEqual() {
        let addedUp = Money(amount: 0.10, currency: .usd) + Money(amount: 0.20, currency: .usd)

        #expect(addedUp == Money(amount: 0.30, currency: .usd))
    }

    @Test
    func aPriceTimesACountIsExact() {
        let line = Money(amount: 0.07, currency: .usd) * 3

        #expect(line == Money(minorUnits: 21, currency: .usd))
    }

    // MARK: - Building from what the catalog sends

    @Test
    func aMajorAmountRoundsToTheNearestMinorUnit() {
        #expect(Money(amount: Decimal(string: "9.994")!, currency: .usd).minorUnits == 999)
        #expect(Money(amount: Decimal(string: "9.995")!, currency: .usd).minorUnits == 1000)
    }

    @Test
    func twoDecimalPricesSurviveBeingWrittenAsLiterals() {
        #expect(Money(amount: 9.99, currency: .usd).minorUnits == 999)
        #expect(Money(amount: 0.07, currency: .usd).minorUnits == 7)
        #expect(Money(amount: 1234.56, currency: .usd).minorUnits == 123_456)
    }

    @Test
    func theAmountReadsBackAsItWentIn() {
        #expect(Money(amount: 9.99, currency: .usd).amount == Decimal(string: "9.99"))
    }

    // MARK: - Totals

    @Test
    func nothingHasNoTotal() {
        #expect(Money.total(of: [Money]()) == nil)
    }

    @Test
    func oneAmountTotalsToItself() {
        let only = Money(amount: 3.50, currency: .usd)

        #expect(Money.total(of: [only]) == only)
    }

    // MARK: - Comparison

    @Test
    func amountsCompareByValue() {
        #expect(Money(amount: 1.00, currency: .usd) < Money(amount: 1.01, currency: .usd))
    }
}
