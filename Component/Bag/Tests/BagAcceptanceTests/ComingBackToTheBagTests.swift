import Foundation
import Testing
import Bag
import Money

@MainActor
@Suite("Coming back to the bag")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the shopper leaves and returns,
/// so what is asserted is what was actually written and read back — through the real store, the
/// real DTOs and real JSON on disk. A fake store here would prove the bag survives a dictionary.
struct ComingBackToTheBagTests {
    @Test("A shopper's bag is still there, and still worth the same, when they come back")
    func bagSurvivesLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 49.99)

        let returning = await shopper.leaveAndComeBack()

        #expect(returning.bag.items.map(\.id) == [pid(2), pid(1)])
        #expect(returning.bag.total == usd(59.98))
    }

    @Test("A bag read back off disk totals to exactly what it totalled before")
    func totalSurvivesStorage() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.choose(productId: 2, atPrice: 0.07)
        shopper.changeQuantity(ofProductId: 2, to: 3)

        let returning = await shopper.leaveAndComeBack()

        #expect(returning.bag.total == usd(10.20))
    }

    @Test("Notices are kept with the bag, so they are still waiting on the next visit")
    func newsSurvivesLeaving() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        shopper.theShopNowSells(shopSells(1, at: 12.99))
        await shopper.comesBack()

        let returning = await shopper.leaveAndComeBack()

        #expect(returning.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
    }

    @Test("A burst of changes ends as the bag the shopper actually left")
    func lastChangeWins() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 1)
        shopper.choose(productId: 2, atPrice: 2)
        shopper.remove(productId: 1)
        shopper.changeQuantity(ofProductId: 2, to: 4)

        let returning = await shopper.leaveAndComeBack()

        #expect(returning.bag.items.map(\.id) == [pid(2)])
        #expect(returning.bag.total == usd(8))
    }

    @Test("Signing in swaps the guest's bag for the shopper's own")
    func signingInSwapsTheBag() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)

        shopper.signIn(asUserId: 42)

        #expect(shopper.bag.isEmpty)

        shopper.choose(productId: 9, atPrice: 5)
        #expect(shopper.bag.total == usd(5))
    }

    @Test("A shopper who signs out gets their guest bag back, not the one they just had")
    func signingOutRestoresTheGuestBag() async {
        let shopper = Shopper()
        shopper.choose(productId: 1, atPrice: 9.99)
        await shopper.writesToSettle()

        shopper.signIn(asUserId: 42)
        shopper.choose(productId: 9, atPrice: 5)
        await shopper.writesToSettle()
        shopper.signOut()

        #expect(shopper.bag.items.map(\.id) == [pid(1)])
        #expect(shopper.bag.total == usd(9.99))
    }

    @Test("Two shoppers' bags never mix, because they are filed under who they belong to")
    func bagsAreKeptApart() async {
        let first = Shopper(signedInAs: 1)
        first.choose(productId: 1, atPrice: 1)
        await first.writesToSettle()

        first.signIn(asUserId: 2)
        first.choose(productId: 2, atPrice: 2)
        await first.writesToSettle()

        first.signIn(asUserId: 1)
        #expect(first.bag.items.map(\.id) == [pid(1)])

        first.signIn(asUserId: 2)
        #expect(first.bag.items.map(\.id) == [pid(2)])
    }

    @Test("A bag left by an older build is put right on the way in, not trusted as it is")
    func repairsWhatItIsHanded() throws {
        let directory = URL.newTemporaryDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try """
        {
          "items": [
            { "productId": 1, "quantity": 1, "lastKnownPriceMinorUnits": 500,
              "currencyCode": "USD", "dateAdded": 100 },
            { "productId": 2, "quantity": 0, "lastKnownPriceMinorUnits": 500,
              "currencyCode": "USD", "dateAdded": 200 },
            { "productId": 1, "quantity": 1, "lastKnownPriceMinorUnits": 500,
              "currencyCode": "USD", "dateAdded": 300 },
            { "productId": 3, "quantity": 2, "lastKnownPriceMinorUnits": 500,
              "currencyCode": "USD", "dateAdded": 400 }
          ],
          "pendingChanges": []
        }
        """.write(to: directory.appending(path: "guest.json"), atomically: true, encoding: .utf8)

        let shopper = Shopper(in: directory)

        #expect(shopper.bag.items.map(\.id) == [pid(3), pid(1)])
        #expect(shopper.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.bag.total == usd(20))
    }

    @Test("A notice naming something this build no longer understands costs the shopper a notice, not their bag")
    func survivesAnUnreadableNotice() throws {
        let directory = URL.newTemporaryDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try """
        {
          "items": [
            { "productId": 1, "quantity": 2, "lastKnownPriceMinorUnits": 999,
              "currencyCode": "USD", "dateAdded": 100 }
          ],
          "pendingChanges": [
            { "kind": "theShopMovedHouse", "productId": 1 }
          ]
        }
        """.write(to: directory.appending(path: "guest.json"), atomically: true, encoding: .utf8)

        let shopper = Shopper(in: directory)

        #expect(shopper.bag.total == usd(19.98))
        #expect(shopper.news.isEmpty)
    }
}
