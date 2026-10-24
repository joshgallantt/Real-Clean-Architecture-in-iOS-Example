import MoneyTestSupport
import Foundation
import ProductTestSupport
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
