import Foundation
import Testing
import Bag
import Money

@MainActor
@Suite("Using the bag")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. Every test here is
/// something a shopper would notice; nothing here names a repository, a store or a use case type.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct UsingTheBagTests {
    @Test("A shopper chooses two things and their bag is worth what they agreed to pay")
    func choosesTwoThings() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        #expect(shopper.bag.itemCount == 2)
        #expect(shopper.bag.total == usd(59.98))
    }

    @Test("Adding prices up is exact, so a total is never a hair off what the lines say")
    func totalsAreExact() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 0.07)
        shopper.changeQuantity(ofProductId: 1, to: 3)
        shopper.choose(productId: 2, atPrice: 9.99)

        #expect(shopper.bag.total == usd(10.20))
    }

    @Test("Choosing the same thing twice is one line with two of it")
    func choosesTheSameThingTwice() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.bag.items.count == 1)
        #expect(shopper.bag.total == usd(19.98))
    }

    @Test("Taking a second one at today's price moves the whole line to today's price")
    func takingAnotherReprices() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 4.99)
        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.bag.total == usd(19.98))
    }

    @Test("Taking three of one thing counts as three items, not one")
    func itemCountCountsEachOne() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 1, to: 3)

        #expect(shopper.bag.items.count == 1)
        #expect(shopper.bag.itemCount == 3)
    }

    @Test("Taking more of something costs proportionally more")
    func changesQuantity() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 1, to: 3)

        #expect(shopper.bag.total == usd(29.97))
    }

    @Test("Changing how many leaves the price alone")
    func quantityChangeKeepsThePrice() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 4.99)

        shopper.changeQuantity(ofProductId: 1, to: 3)

        #expect(shopper.bag.total == usd(14.97))
    }

    @Test("The newest thing chosen sits at the top of the bag")
    func newestFirst() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 1)
        shopper.choose(productId: 2, atPrice: 2)

        #expect(shopper.bag.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Putting something back leaves the rest of the bag alone")
    func removesSomething() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.remove(productId: 1)

        #expect(shopper.bag.items.map(\.id) == [pid(2)])
        #expect(shopper.bag.total == usd(49.99))
    }

    @Test("Asking for none of something is how a shopper puts it back")
    func askingForNoneRemoves() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 1, to: 0)

        #expect(shopper.bag.isEmpty)
    }

    @Test("An emptied bag is worth nothing at all, not zero of something")
    func emptiedBag() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.remove(productId: 1)

        #expect(shopper.bag.isEmpty)
        #expect(shopper.bag.total == nil)
    }

    @Test("Changing how many of something the shopper never chose changes nothing")
    func changingSomethingNotThere() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 99, to: 5)

        #expect(shopper.bag.items.map(\.id) == [pid(1)])
        #expect(shopper.bag.total == usd(9.99))
    }

    @Test("Putting back something that was never in the bag changes nothing")
    func removingSomethingNotThere() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.remove(productId: 99)

        #expect(shopper.bag.items.map(\.id) == [pid(1)])
    }
}
