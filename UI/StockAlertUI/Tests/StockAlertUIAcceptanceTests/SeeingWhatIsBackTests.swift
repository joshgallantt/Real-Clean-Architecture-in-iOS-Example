import Tracking
import Foundation
import ProductTestSupport
import Testing
import Product
@testable import StockAlertUI

@MainActor
@Suite("Seeing what is back, and what is not yet", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: one set of alerts, one list.
/// Whether something on it is back is a fact about the shop's shelf right now, so it changes the
/// moment the thing returns — nothing has to have been told, and nothing has to be marked.
struct SeeingWhatIsBackTests {
    private let tab = TrackingContext.screen("wishlist")

    @Test("What is still sold out is shown, as sold out")
    func stillSoldOutIsShown() async throws {
        let waiter = AWaiter()
        waiter.shop.sells(1)
        waiter.shop.soldOut = [pid(1)]
        await waiter.list.onAppear(in: tab)

        try await waiter.asksAbout(1)
        await waiter.settle()

        #expect(waiter.list.products.map(\.id) == [pid(1)])
        #expect(waiter.list.products.map(\.availability.isAvailable) == [false])
    }

    @Test("What the shop has again is shown first and can be bought, from the very same alerts")
    func whatIsBackComesFirst() async throws {
        let waiter = AWaiter()
        waiter.shop.sells(1, 2)
        waiter.shop.soldOut = [pid(1)]
        await waiter.list.onAppear(in: tab)

        try await waiter.asksAbout(1, 2)
        await waiter.settle()

        #expect(waiter.list.products.map(\.id) == [pid(2), pid(1)])
        #expect(waiter.list.products.map(\.availability.isAvailable) == [true, false])
    }

    @Test("Something the shop no longer sells is not shown")
    func discontinued() async throws {
        let waiter = AWaiter()
        waiter.shop.sells(1)
        await waiter.list.onAppear(in: tab)

        try await waiter.asksAbout(1, 2)
        await waiter.settle()

        #expect(waiter.list.products.map(\.id) == [pid(1)])
    }

    @Test("A shop that cannot be reached leaves the list as it was, and says so")
    func cannotBeReached() async throws {
        let waiter = AWaiter()
        waiter.shop.sells(1)
        await waiter.list.onAppear(in: tab)
        try await waiter.asksAbout(1)
        await waiter.settle()

        waiter.shop.cannotBeReached = true
        try await waiter.asksAbout(1, 2)
        await waiter.settle()

        #expect(waiter.list.products.map(\.id) == [pid(1)])
        #expect(waiter.snackbars.shown.first?.title == "Stock Alerts Won't Load")
    }

    @Test("Clearing turns off every alert on the list, back or not")
    func clearingTakesEverything() async throws {
        let waiter = AWaiter()
        waiter.shop.sells(1, 2)
        waiter.shop.soldOut = [pid(1)]
        await waiter.list.onAppear(in: tab)
        try await waiter.asksAbout(1, 2)
        await waiter.settle()

        waiter.list.didConfirmClear(in: tab)
        await waiter.settle()

        #expect(waiter.cleared == [pid(2), pid(1)])
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingNothing() async {
        let waiter = AWaiter()
        await waiter.list.onAppear(in: tab)
        await waiter.settle()

        waiter.list.didConfirmClear(in: tab)
        await waiter.settle()

        #expect(waiter.cleared.isEmpty)
    }
}
