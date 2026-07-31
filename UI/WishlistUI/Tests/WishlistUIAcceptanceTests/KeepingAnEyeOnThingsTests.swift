import Foundation
import Testing
import Product
@testable import WishlistUI

@MainActor
@Suite("Keeping an eye on things", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: what a shopper sees on the
/// tab they keep things on, whether the thing they kept was a fave or something they are waiting for.
struct KeepingAnEyeOnThingsTests {
    @Test("What a shopper has kept is filled in from the shop")
    func showsWhatIsKept() async {
        let keeper = AKeeper()
        keeper.shop.sells(1, 2)
        keeper.list.onAppear()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.list.products.map(\.id) == [pid(1), pid(2)])
        #expect(keeper.list.savedCount == 2)
    }

    @Test("Keeping nothing shows nothing, and asks the shop nothing")
    func nothingKept() async {
        let keeper = AKeeper()
        keeper.list.onAppear()

        await keeper.settle()

        #expect(keeper.list.isEmpty)
        #expect(keeper.shop.asked.isEmpty)
    }

    @Test("Something the shop no longer answers about is not shown, and the shopper is told")
    func discontinued() async {
        let keeper = AKeeper()
        keeper.shop.sells(1)
        keeper.list.onAppear()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.list.products.map(\.id) == [pid(1)])
        #expect(keeper.list.somethingHasBeenDiscontinued)
    }

    /// The one that matters most: a dropped connection must never read as the shop closing down.
    @Test("A shop that cannot be reached says nothing about anything")
    func cannotBeReached() async {
        let keeper = AKeeper()
        keeper.shop.cannotBeReached = true
        keeper.list.onAppear()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.list.somethingHasBeenDiscontinued == false)
        #expect(keeper.snackbars.shown.first?.title == "Couldn't Load")
    }

    @Test("The count is what the shopper has kept, not what is on screen")
    func countIsOfEverythingKept() async {
        let keeper = AKeeper()
        keeper.pageSize = 2
        keeper.shop.stillSells = Set((1...5).map(pid))
        keeper.list.onAppear()

        keeper.keeps(idsUpTo: 5)
        await keeper.settle()

        #expect(keeper.list.products.count == 2)
        #expect(keeper.list.savedCount == 5)
    }

    @Test("Reaching the end of the list asks for the next page")
    func paging() async {
        let keeper = AKeeper()
        keeper.pageSize = 2
        keeper.shop.stillSells = Set((1...5).map(pid))
        keeper.list.onAppear()
        keeper.keeps(idsUpTo: 5)
        await keeper.settle()

        keeper.list.onReachEnd()
        await keeper.settle()

        #expect(keeper.list.products.count == 4)
    }

    @Test("Something already filled in is not asked about again")
    func doesNotReaskForWhatItHas() async {
        let keeper = AKeeper()
        keeper.shop.sells(1, 2)
        keeper.list.onAppear()
        keeper.keeps(1)
        await keeper.settle()

        keeper.keeps(1, 2)
        await keeper.settle()

        #expect(keeper.shop.asked == [[pid(1)], [pid(2)]])
    }

    @Test("Something the shopper stops keeping goes, and is not asked about again")
    func stopsKeeping() async {
        let keeper = AKeeper()
        keeper.shop.sells(1, 2)
        keeper.list.onAppear()
        keeper.keeps(1, 2)
        await keeper.settle()

        keeper.stopsKeeping(1)
        await keeper.settle()

        #expect(keeper.list.products.map(\.id) == [pid(2)])
        #expect(keeper.shop.asked == [[pid(1), pid(2)]])
    }
}
