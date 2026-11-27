import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the one rule that says what a bag
/// truthfully is and what changed about it, a case at a time. The acceptance suite says what a
/// shopper was shown; these name the rule that decided it.
@Suite("Checking a bag against the shop")
struct CheckedBagTests {
    private func check(_ bag: Bag, against products: Product...) -> CheckedBag {
        bag.checked(against: products, asked: Set(bag.items.map(\.productId)))
    }

    // MARK: - Nothing to say

    @Test("A shop asking the same price, with enough to go round, changes nothing")
    func nothingChanged() {
        let bag = Bag(items: [item(1, quantity: 2, at: 9.99)])

        let checked = check(bag, against: .fixture(id: 1, price: 9.99, availability: .inStock(remaining: 2)))

        #expect(checked.bag == bag)
        #expect(checked.changes.isEmpty)
    }

    @Test("An empty bag has nothing to check")
    func emptyBag() {
        let checked = Bag().checked(against: [.fixture(id: 1)], asked: [])

        #expect(checked.bag.isEmpty)
        #expect(checked.changes.isEmpty)
    }

    @Test("A price that did not move by a penny is no change, and one that moved by a penny is")
    func exactPrices() {
        let bag = Bag(items: [item(1, at: 0.10)])

        #expect(check(bag, against: .fixture(id: 1, price: 0.10)).changes.isEmpty)
        #expect(check(bag, against: .fixture(id: 1, price: 0.11)).changes
            == [.priceWentUp(productId: pid(1), from: usd(0.10), to: usd(0.11))])
    }

    // MARK: - Each kind of change

    @Test("A price that went up is a rise from the kept price, and the line takes today's price")
    func priceWentUp() {
        let checked = check(Bag(items: [item(1, quantity: 2, at: 9.99)]), against: .fixture(id: 1, price: 12.99))

        #expect(checked.changes == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(checked.bag.total == usd(25.98))
    }

    @Test("A price that came down is a fall from the kept price, and the line takes today's price")
    func priceWentDown() {
        let checked = check(Bag(items: [item(1, at: 9.99)]), against: .fixture(id: 1, price: 4.99))

        #expect(checked.changes == [.priceWentDown(productId: pid(1), from: usd(9.99), to: usd(4.99))])
        #expect(checked.bag.total == usd(4.99))
    }

    @Test("Asking for more than the shop has is cut to what is left, and says how many that is")
    func onlySomeLeft() {
        let checked = check(
            Bag(items: [item(1, quantity: 5, at: 10)]),
            against: .fixture(id: 1, price: 10, availability: .inStock(remaining: 2))
        )

        #expect(checked.changes == [.onlySomeLeft(productId: pid(1), available: 2)])
        #expect(checked.bag.quantity(of: pid(1)) == 2)
        #expect(checked.bag.total == usd(20))
    }

    @Test("Asking for exactly what the shop has is not a shortage")
    func exactlyEnough() {
        let checked = check(
            Bag(items: [item(1, quantity: 2, at: 10)]),
            against: .fixture(id: 1, price: 10, availability: .inStock(remaining: 2))
        )

        #expect(checked.changes.isEmpty)
        #expect(checked.bag.quantity(of: pid(1)) == 2)
    }

    @Test("Something sold out is not a line any more, and says so")
    func soldOut() {
        let checked = check(
            Bag(items: [item(1, at: 9.99)]),
            against: .fixture(id: 1, availability: .outOfStock)
        )

        #expect(checked.changes == [.soldOut(productId: pid(1))])
        #expect(checked.bag.isEmpty)
    }

    @Test("What something's price did on the way out is not worth saying")
    func soldOutAndRepriced() {
        let checked = check(
            Bag(items: [item(1, at: 9.99)]),
            against: .fixture(id: 1, price: 12.99, availability: .outOfStock)
        )

        #expect(checked.changes == [.soldOut(productId: pid(1))])
    }

    // MARK: - More than one thing at once

    @Test("A line that is both dearer and short is both, because they are two facts")
    func dearerAndShort() {
        let checked = check(
            Bag(items: [item(1, quantity: 5, at: 10)]),
            against: .fixture(id: 1, price: 12, availability: .inStock(remaining: 2))
        )

        #expect(checked.changes == [
            .priceWentUp(productId: pid(1), from: usd(10), to: usd(12)),
            .onlySomeLeft(productId: pid(1), available: 2)
        ])
        #expect(checked.bag.total == usd(24))
    }

    @Test("Changes are told in the order the bag keeps its lines, the newest first")
    func inTheBagsOrder() {
        let bag = Bag(items: [
            item(1, at: 5, added: Date(timeIntervalSince1970: 1)),
            item(2, at: 5, added: Date(timeIntervalSince1970: 2)),
            item(3, at: 5, added: Date(timeIntervalSince1970: 3))
        ])

        let checked = check(
            bag,
            against: .fixture(id: 1, price: 6), .fixture(id: 2, availability: .outOfStock), .fixture(id: 3, price: 4)
        )

        #expect(checked.changes == [
            .priceWentDown(productId: pid(3), from: usd(5), to: usd(4)),
            .soldOut(productId: pid(2)),
            .priceWentUp(productId: pid(1), from: usd(5), to: usd(6))
        ])
        #expect(checked.bag.items.map(\.productId) == [pid(3), pid(1)])
    }

    // MARK: - What the shop did not say

    @Test("Something asked about and not described has been stopped: it goes, and nothing is said")
    func stoppedSelling() {
        let bag = Bag(items: [item(1, at: 9.99), item(2, at: 5)])

        let checked = check(bag, against: .fixture(id: 2, price: 5))

        #expect(checked.bag.items.map(\.productId) == [pid(2)])
        #expect(checked.changes.isEmpty)
    }

    @Test("Something not asked about is left exactly as it was")
    func notAskedAbout() {
        let bag = Bag(items: [item(1, quantity: 3, at: 9.99), item(2, at: 5)])

        let checked = bag.checked(against: [.fixture(id: 2, price: 5)], asked: [pid(2)])

        #expect(checked.bag == bag)
        #expect(checked.changes.isEmpty)
    }

    @Test("A shop that could not be reached was asked nothing, so nothing changes and nothing goes")
    func shopNotReached() {
        let bag = Bag(items: [item(1, at: 9.99), item(2, at: 49.99)])

        let checked = bag.checked(against: [], asked: [])

        #expect(checked.bag == bag)
        #expect(checked.changes.isEmpty)
    }

    @Test("A product the shop describes that the bag does not hold changes nothing")
    func unknownProduct() {
        let bag = Bag(items: [item(1, at: 9.99)])

        let checked = bag.checked(
            against: [.fixture(id: 1, price: 9.99), .fixture(id: 99, price: 1, availability: .outOfStock)],
            asked: [pid(1), pid(99)]
        )

        #expect(checked.bag == bag)
        #expect(checked.changes.isEmpty)
    }

    // MARK: - What the answer keeps, and what it leaves alone

    @Test("The answer keeps what was asked and what the shop said, so it can be held against the bag again")
    func keepsTheAnswer() {
        let lipstick = Product.fixture(id: 1, price: 12.99)

        let checked = Bag(items: [item(1, at: 9.99)]).checked(against: [lipstick], asked: [pid(1)])

        #expect(checked.products == [lipstick])
        #expect(checked.asked == [pid(1)])
    }

    @Test("A line keeps its place and when it was added, whatever the shop changed about it")
    func keepsItsPlace() {
        let bag = Bag(items: [item(1, quantity: 4, at: 5, added: .distantPast), item(2, at: 5, added: .now)])

        let checked = check(
            bag,
            against: .fixture(id: 1, price: 6, availability: .inStock(remaining: 1)), .fixture(id: 2, price: 5)
        )

        #expect(checked.bag.items.map(\.productId) == [pid(2), pid(1)])
        #expect(checked.bag.items.map(\.dateAdded) == bag.items.map(\.dateAdded))
    }

    @Test("Checking never alters the bag it was asked of")
    func sideEffectFree() {
        let before = Bag(items: [item(1, quantity: 5, at: 9.99)])

        _ = check(before, against: .fixture(id: 1, price: 12.99, availability: .inStock(remaining: 1)))

        #expect(before.quantity(of: pid(1)) == 5)
        #expect(before.total == usd(49.95))
    }

    @Test("A bag that is already truthful has nothing more to be told")
    func checkingTheTruthfulBagAgain() {
        let products: [Product] = [
            .fixture(id: 1, price: 12, availability: .inStock(remaining: 2)),
            .fixture(id: 2, availability: .outOfStock)
        ]
        let kept = Bag(items: [item(1, quantity: 5, at: 10), item(2, at: 5), item(3, at: 1)])
        let asked: Set<ProductID> = [pid(1), pid(2), pid(3)]

        let truthful = kept.checked(against: products, asked: asked).bag
        let again = truthful.checked(against: products, asked: asked)

        #expect(again.bag == truthful)
        #expect(again.changes.isEmpty)
    }

    // MARK: - Keeping a bag as it was seen

    @Test("Setting the lines that differ, and none of each that has gone, makes one bag the other")
    func linesToBecome() {
        let kept = Bag(items: [
            item(1, quantity: 5, at: 10, added: Date(timeIntervalSince1970: 3)),
            item(2, at: 5, added: Date(timeIntervalSince1970: 2)),
            item(3, at: 1, added: Date(timeIntervalSince1970: 1))
        ])
        let seen = check(
            kept,
            against: .fixture(id: 1, price: 12, availability: .inStock(remaining: 2)),
            .fixture(id: 2, availability: .outOfStock),
            .fixture(id: 3, price: 1)
        ).bag

        let lines = kept.lines(toBecome: seen)

        #expect(lines.map(\.productId) == [pid(2), pid(1)])
        #expect(lines.map(\.quantity) == [0, 2])
        #expect(lines.reduce(kept) { $0.setting($1) } == seen)
    }

    @Test("A bag that is already the other has no lines to set")
    func nothingToSet() {
        let bag = Bag(items: [item(1, at: 5), item(2, at: 6)])

        #expect(bag.lines(toBecome: bag).isEmpty)
    }
}
