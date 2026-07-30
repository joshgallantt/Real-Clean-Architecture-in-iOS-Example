import Foundation
import Testing
@testable import Money

struct MoneyTests {

    // MARK: - Exactness, which is the whole reason this type exists

    @Test
    func addingPricesIsExact() {
        let total = [
            Money(amount: 9.99, currency: .usd),
            Money(amount: 49.99, currency: .usd)
        ].total()

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

    /// Stated with exact decimals rather than float literals: `9.995` written as a literal
    /// is a `Double` first, and lands a hair below the halfway point it looks like.
    @Test
    func aMajorAmountRoundsToTheNearestMinorUnit() {
        #expect(Money(amount: Decimal(string: "9.994")!, currency: .usd).minorUnits == 999)
        #expect(Money(amount: Decimal(string: "9.995")!, currency: .usd).minorUnits == 1000)
    }

    /// A price with the precision a currency actually has survives a float literal, because
    /// rounding to the nearest minor unit absorbs noise that small. This is what makes
    /// `Money(amount: 9.99, currency: .usd)` safe to write in tests and at the DTO boundary.
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
        #expect([Money]().total() == nil)
    }

    @Test
    func oneAmountTotalsToItself() {
        let only = Money(amount: 3.50, currency: .usd)

        #expect([only].total() == only)
    }

    // MARK: - Comparison

    @Test
    func amountsCompareByValue() {
        #expect(Money(amount: 1.00, currency: .usd) < Money(amount: 1.01, currency: .usd))
    }
}
