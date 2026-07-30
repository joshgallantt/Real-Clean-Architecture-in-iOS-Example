import Foundation
import Testing
import Bag
import Money

@MainActor
@Suite("Using the bag")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. What no layer test
/// can show is that the layers fit together.
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

    @Test("Taking more of something costs proportionally more")
    func changesQuantity() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.changeQuantity(ofProductId: 1, to: 3)

        #expect(shopper.bag.total == usd(29.97))
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

    @Test("An emptied bag is worth nothing at all, not zero of something")
    func emptiedBag() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.remove(productId: 1)

        #expect(shopper.bag.isEmpty)
        #expect(shopper.bag.total == nil)
    }

    @Test("A shopper's bag is still there, and still worth the same, when they come back")
    func bagSurvivesLeaving() async {
        let store = InMemoryBagStore()
        let firstVisit = Shopper(store: store)
        firstVisit.choose(productId: 1, atPrice: 9.99)
        firstVisit.choose(productId: 2, atPrice: 49.99)
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Shopper(store: store)

        #expect(nextVisit.bag.items.map(\.id) == [pid(2), pid(1)])
        #expect(nextVisit.bag.total == usd(59.98))
    }

    @Test("A bag read back off disk totals to exactly what it totalled before")
    func totalSurvivesStorage() async {
        let store = InMemoryBagStore()
        let firstVisit = Shopper(store: store)
        firstVisit.choose(productId: 1, atPrice: 9.99)
        firstVisit.choose(productId: 2, atPrice: 0.07)
        firstVisit.changeQuantity(ofProductId: 2, to: 3)
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Shopper(store: store)

        #expect(nextVisit.bag.total == usd(10.20))
    }

    @Test("Signing in swaps the guest's bag for the shopper's own")
    func signingInSwapsTheBag() async {
        let store = InMemoryBagStore()
        let shopper = Shopper(store: store)
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.signIn(asUserId: 42)

        #expect(shopper.bag.isEmpty)

        shopper.choose(productId: 9, atPrice: 5)
        #expect(shopper.bag.total == usd(5))
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

        #expect(shopper.bag.items.map(\.id) == [pid(1)])
        #expect(shopper.bag.total == usd(9.99))
    }
}

@MainActor
@Suite("Being told what the shop changed")
struct BeingToldWhatChangedTests {
    @Test("A shopper is told a price moved, and the bag is worth the new price")
    func priceMoved() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopSells(1, at: 12.99))

        #expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("A shopper is told something has gone, and it is out of their bag")
    func somethingWent() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.shopSays(shopHasSoldOutOf(1))

        #expect(shopper.news.noLongerAvailable == [.noLongerAvailable(productId: pid(1))])
        #expect(shopper.bag.isEmpty)
    }

    @Test("A shopper asking for more than the shop has gets what it has, and is told")
    func onlySomeLeft() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 10)
        shopper.changeQuantity(ofProductId: 1, to: 5)

        shopper.shopSays(shopSells(1, at: 10, remaining: 2))

        #expect(shopper.news.shortages == [.onlySomeLeft(productId: pid(1), available: 2)])
        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.bag.total == usd(20))
    }

    @Test("Saying they have seen it clears the notice without touching the bag")
    func seenIt() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.shopSays(shopSells(1, at: 12.99))

        shopper.seen(productId: 1)

        #expect(shopper.news.isEmpty)
        #expect(shopper.bag.total == usd(12.99))
    }

    @Test("Choosing something again spends the news that it had gone")
    func choosingAgainSpendsTheNews() {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.shopSays(shopHasSoldOutOf(1))

        shopper.choose(productId: 1, atPrice: 9.99)

        #expect(shopper.news.isEmpty)
    }

    @Test("Notices are kept with the bag, so they are still waiting on the next visit")
    func newsSurvivesLeaving() async {
        let store = InMemoryBagStore()
        let firstVisit = Shopper(store: store)
        firstVisit.choose(productId: 1, atPrice: 9.99)
        firstVisit.shopSays(shopSells(1, at: 12.99))
        try? await Task.sleep(for: .milliseconds(50))

        let nextVisit = Shopper(store: store)

        #expect(nextVisit.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
    }
}
