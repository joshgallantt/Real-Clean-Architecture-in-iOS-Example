import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Product
@testable import Bag

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
