import Foundation
import ProductTestSupport
import Testing
import Product
@testable import WishlistUI

@MainActor
@Suite("Telling what is waited on from what is back", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: one set of asks, two lists.
/// Which list something is on is a fact about the shop's shelf right now, so it moves the moment
/// the thing returns — nothing has to have been told, and nothing has to be marked.
struct TellingWaitedOnFromBackTests {
    @Test("What is still sold out is what the waitlist shows")
    func waitlistIsTheSoldOutOnes() async {
        let keeper = AKeeper()
        keeper.keeping = { !$0.availability.isAvailable }
        keeper.shop.sells(1, 2)
        keeper.shop.soldOut = [pid(1)]
        keeper.list.onAppear()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.list.products.map(\.id) == [pid(1)])
    }

    @Test("What the shop has again is what Back in Stock shows, from the very same asks")
    func backInStockIsTheRest() async {
        let keeper = AKeeper()
        keeper.keeping = { $0.availability.isAvailable }
        keeper.shop.sells(1, 2)
        keeper.shop.soldOut = [pid(1)]
        keeper.list.onAppear()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.list.products.map(\.id) == [pid(2)])
    }

    @Test("Clearing takes away everything on that list, and nothing off the other")
    func clearingTakesOnlyItsOwn() async {
        let keeper = AKeeper()
        keeper.keeping = { !$0.availability.isAvailable }
        keeper.shop.sells(1, 2)
        keeper.shop.soldOut = [pid(1)]
        keeper.list.onAppear()
        keeper.keeps(1, 2)
        await keeper.settle()

        keeper.list.didConfirmClear()
        await keeper.settle()

        #expect(keeper.cleared == [pid(1)])
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingNothing() async {
        let keeper = AKeeper()
        keeper.list.onAppear()
        await keeper.settle()

        keeper.list.didConfirmClear()
        await keeper.settle()

        #expect(keeper.cleared.isEmpty)
    }
}
