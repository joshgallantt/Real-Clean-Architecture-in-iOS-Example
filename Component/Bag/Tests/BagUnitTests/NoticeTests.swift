import Foundation
import Testing
import Money
import Product
@testable import Bag

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: which notice a thing is, and what a list of
/// them can be asked. These name the rule; the acceptance suite names the journey.
@Suite("Notice")
struct NoticeTests {
    @Test("Every notice knows which product it is about")
    func productId() {
        #expect(Notice.outOfStock(productId: pid(1)).productId == pid(1))
        #expect(Notice.onlySomeLeft(productId: pid(2), available: 1).productId == pid(2))
        #expect(Notice.priceWentUp(productId: pid(3), from: usd(1), to: usd(2)).productId == pid(3))
        #expect(Notice.priceWentDown(productId: pid(4), from: usd(2), to: usd(1)).productId == pid(4))
    }

    @Test("Every notice knows what kind it is")
    func kind() {
        #expect(Notice.outOfStock(productId: pid(1)).kind == .outOfStock)
        #expect(Notice.onlySomeLeft(productId: pid(1), available: 1).kind == .onlySomeLeft)
        #expect(Notice.priceWentUp(productId: pid(1), from: usd(1), to: usd(2)).kind == .priceWentUp)
        #expect(Notice.priceWentDown(productId: pid(1), from: usd(2), to: usd(1)).kind == .priceWentDown)
    }

    @Test("Only a sell-out is about something that has left the bag")
    func isAboutSomethingGone() {
        #expect(Notice.outOfStock(productId: pid(1)).isAboutSomethingGone)
        #expect(Notice.onlySomeLeft(productId: pid(1), available: 1).isAboutSomethingGone == false)
        #expect(Notice.priceWentUp(productId: pid(1), from: usd(1), to: usd(2)).isAboutSomethingGone == false)
    }

    @Test("A price notice remembers what the shopper was last shown")
    func priceLastSeen() {
        #expect(Notice.priceWentUp(productId: pid(1), from: usd(9), to: usd(12)).priceLastSeen == usd(9))
        #expect(Notice.priceWentDown(productId: pid(1), from: usd(9), to: usd(4)).priceLastSeen == usd(9))
    }

    @Test("Notices that are not about price remember no price")
    func noPriceLastSeen() {
        #expect(Notice.outOfStock(productId: pid(1)).priceLastSeen == nil)
        #expect(Notice.onlySomeLeft(productId: pid(1), available: 2).priceLastSeen == nil)
    }

    @Test("A price that went up is a rise")
    func priceMoveUp() {
        #expect(Notice.priceMove(productId: pid(1), from: usd(9), to: usd(12))
            == .priceWentUp(productId: pid(1), from: usd(9), to: usd(12)))
    }

    @Test("A price that came down is a fall")
    func priceMoveDown() {
        #expect(Notice.priceMove(productId: pid(1), from: usd(9), to: usd(4))
            == .priceWentDown(productId: pid(1), from: usd(9), to: usd(4)))
    }

    @Test("A price that did not move is no news at all")
    func priceMoveUnchanged() {
        #expect(Notice.priceMove(productId: pid(1), from: usd(9.99), to: usd(9.99)) == nil)
    }

    @Test("A price that did not move by a penny is still no news")
    func priceMoveExact() {
        #expect(Notice.priceMove(productId: pid(1), from: usd(0.10), to: usd(0.10)) == nil)
        #expect(Notice.priceMove(productId: pid(1), from: usd(0.10), to: usd(0.11)) != nil)
    }
}

@Suite("Notices")
struct NoticesTests {
    private let sellOut = Notice.outOfStock(productId: pid(1))
    private let shortage = Notice.onlySomeLeft(productId: pid(2), available: 2)
    private let rise = Notice.priceWentUp(productId: pid(3), from: usd(5), to: usd(7))
    private let fall = Notice.priceWentDown(productId: pid(4), from: usd(7), to: usd(5))

    private var all: Notices { Notices([sellOut, shortage, rise, fall]) }

    @Test("No notices is no news")
    func empty() {
        #expect(Notices().isEmpty)
        #expect(Notices().all.isEmpty)
    }

    @Test("Asking for one kind gives that kind")
    func ofOneKind() {
        #expect(all.of(.outOfStock) == [sellOut])
        #expect(all.of(.onlySomeLeft) == [shortage])
    }

    @Test("Asking for two kinds gives both")
    func ofTwoKinds() {
        #expect(all.of(.priceWentUp, .priceWentDown) == [rise, fall])
    }

    @Test("Asking for a kind nothing is gives nothing")
    func ofNoneOfThatKind() {
        #expect(Notices([sellOut]).of(.priceWentUp).isEmpty)
    }

    @Test("What has gone is what left the bag")
    func gone() {
        #expect(all.gone == [sellOut])
    }

    @Test("Everything about one product, whatever kind")
    func about() {
        let two = Notices([sellOut, .priceWentUp(productId: pid(1), from: usd(1), to: usd(2))])

        #expect(two.about(pid(1)).count == 2)
    }

    @Test("Nothing is about a product with no news")
    func aboutNothing() {
        #expect(all.about(pid(99)).isEmpty)
    }

    @Test("The price last seen comes from whichever notice remembers one")
    func priceLastSeen() {
        #expect(all.priceLastSeen(forProductId: pid(3)) == usd(5))
    }

    @Test("A product with no price notice has no price last seen")
    func noPriceLastSeen() {
        #expect(all.priceLastSeen(forProductId: pid(1)) == nil)
    }

    @Test("Acknowledging clears everything about that product")
    func acknowledging() {
        let two = Notices([sellOut, .priceWentUp(productId: pid(1), from: usd(1), to: usd(2)), rise])

        #expect(two.acknowledging(pid(1)).all == [rise])
    }

    @Test("Acknowledging leaves other products alone")
    func acknowledgingOne() {
        #expect(all.acknowledging(pid(1)).all.count == 3)
    }

    @Test("Acknowledging something with no news changes nothing")
    func acknowledgingNothing() {
        #expect(all.acknowledging(pid(99)) == all)
    }

    @Test("Acknowledging never changes the list it was asked of")
    func sideEffectFree() {
        let before = all
        _ = before.acknowledging(pid(1))

        #expect(before.all.count == 4)
    }
}
