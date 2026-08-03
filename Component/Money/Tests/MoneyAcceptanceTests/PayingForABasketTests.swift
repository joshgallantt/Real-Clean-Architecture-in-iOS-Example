import Foundation
import Testing
import Money

@Suite("Paying for a basket")
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: what a shopper is charged and
/// what they owe, in the words they would use for it.
///
/// Fowler, *PoEAA* (2002) — Money: the rules stated here are the business's, not the language's. A
/// shopper who is overcharged by a penny has been overcharged, however the arithmetic got there.
struct PayingForABasketTests {
    @Test("A shopper owes the exact total of everything in their basket")
    func totalOfABasket() {
        let till = Till()

        till.rings(9.99)
        till.rings(49.99)

        #expect(till.amountDue == till.price(59.98))
    }

    @Test("Taking three of the same thing costs three times the price")
    func severalOfTheSameThing() {
        let till = Till()

        till.rings(0.07, times: 3)

        #expect(till.amountDue == till.price(0.21))
    }

    @Test("An empty basket owes nothing at all")
    func nothingInTheBasket() {
        let till = Till()

        #expect(till.amountDue == nil)
    }

    @Test("A price that falls between pennies is charged to the nearer penny")
    func roundingToWhatIsActuallyPaid() {
        let dearer = Till()
        let cheaper = Till()

        dearer.rings(Decimal(string: "9.995")!)
        cheaper.rings(Decimal(string: "9.994")!)

        #expect(dearer.amountDue == dearer.price(10.00))
        #expect(cheaper.amountDue == cheaper.price(9.99))
    }

    @Test("Two baskets reaching the same amount cost the same, however they got there")
    func sameAmountByAnotherRoute() {
        let inParts = Till()
        let inOne = Till()

        inParts.rings(0.10)
        inParts.rings(0.20)
        inOne.rings(0.30)

        #expect(inParts.amountDue == inOne.amountDue)
    }
}
