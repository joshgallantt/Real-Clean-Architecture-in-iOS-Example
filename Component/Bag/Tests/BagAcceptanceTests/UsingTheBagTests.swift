import Foundation
import Testing
import Bag

/// Journeys through the whole bag feature — use cases, repository and store — with no
/// catalog anywhere in sight. That is the thing worth proving: everything a shopper
/// does with their bag, and everything the bag is worth, works without the shop.
@MainActor
@Suite("Using the bag")
struct UsingTheBagTests {

    @Test("A shopper chooses two things and their bag is worth what they agreed to pay")
    func choosesTwoThings() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        #expect(shopper.bag.itemCount == 2)
        #expect(shopper.bag.total.cents == 5998)
    }

    @Test("Choosing the same thing twice is one line with two of it")
    func choosesTheSameThingTwice() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.bag.items.count == 1)
        #expect(shopper.bag.total.cents == 1998)
    }

    @Test("Taking a second one at today's price moves the whole line to today's price")
    func takingAnotherReprices() {
        let shopper = Shopper()

        shopper.choose(productId: 1, atPrice: 4.99)
        shopper.choose(productId: 1, atPrice: 9.99)

        // Leaving the first at the sale price would either short the shop or overcharge
        // the shopper, depending which way the price moved.
        #expect(shopper.bag.total.cents == 1998)
    }

    @Test("Taking more of something costs proportionally more")
    func changesQuantity() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 1, to: 3)

        #expect(shopper.bag.total.cents == 2997)
    }

    @Test("Putting something back leaves the rest of the bag alone")
    func removesSomething() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        shopper.remove(productId: 1)

        #expect(shopper.bag.items.map(\.id) == [2])
        #expect(shopper.bag.total.cents == 4999)
    }

    @Test("A shopper's bag is still there, and still worth the same, when they come back")
    func bagSurvivesLeaving() async {
        let store = InMemoryBagStore()
        let firstVisit = Shopper(store: store)
        firstVisit.choose(productId: 1, atPrice: 9.99)
        firstVisit.choose(productId: 2, atPrice: 49.99)
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Shopper(store: store)

        #expect(nextVisit.bag.items.map(\.id) == [2, 1])
        #expect(nextVisit.bag.total.cents == 5998)
    }

    @Test("Signing in swaps the guest's bag for the shopper's own")
    func signingInSwapsTheBag() async {
        let store = InMemoryBagStore()
        let shopper = Shopper(store: store)
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.signIn(asUserId: 42)

        #expect(shopper.bag.isEmpty)

        shopper.choose(productId: 9, atPrice: 5)
        #expect(shopper.bag.total.cents == 500)
    }

    @Test("A shopper who signs out gets their guest bag back, not the one they just had")
    func signingOutRestoresTheGuestBag() async {
        let store = InMemoryBagStore()
        let shopper = Shopper(store: store)
        shopper.choose(productId: 1, atPrice: 9.99)
        try? await Task.sleep(for: .milliseconds(50))

        shopper.signIn(asUserId: 42)
        shopper.choose(productId: 9, atPrice: 5)
        try? await Task.sleep(for: .milliseconds(50))
        shopper.signOut()

        #expect(shopper.bag.items.map(\.id) == [1])
        #expect(shopper.bag.total.cents == 999)
    }
}

