import Foundation
import Testing
import Product
@testable import Waitlist

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the waitlist's own rules. The acceptance
/// suite says a shopper joined and left; these say what the list does when they join twice, or
/// leave something they were never on.
@Suite("Waitlist")
struct WaitlistTests {
    private func item(_ id: Int, at date: Date = Date()) -> WaitlistItem {
        WaitlistItem(productId: ProductID(rawValue: id), dateAdded: date)
    }

    @Test("A new waitlist is empty")
    func empty() {
        #expect(Waitlist().isEmpty)
        #expect(Waitlist().itemCount == 0)
    }

    @Test("Joining puts it on the list")
    func adding() {
        let waitlist = Waitlist().adding(item(1))

        #expect(waitlist.contains(productId: ProductID(rawValue: 1)))
        #expect(waitlist.itemCount == 1)
    }

    @Test("Nothing is waited on until it is joined")
    func notWaiting() {
        #expect(Waitlist().contains(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Joining twice for the same thing is one place on the list")
    func joiningTwice() {
        let waitlist = Waitlist().adding(item(1)).adding(item(1))

        #expect(waitlist.itemCount == 1)
    }

    @Test("The newest comes first")
    func newestFirst() {
        let waitlist = Waitlist(items: [
            item(1, at: .distantPast),
            item(2, at: .now)
        ])

        #expect(waitlist.items.map(\.productId) == [ProductID(rawValue: 2), ProductID(rawValue: 1)])
    }

    @Test("Building one from duplicates keeps one of each")
    func initialiserDeduplicates() {
        #expect(Waitlist(items: [item(1), item(1), item(2)]).itemCount == 2)
    }

    @Test("Leaving takes it off")
    func removing() {
        let waitlist = Waitlist().adding(item(1)).removing(productId: ProductID(rawValue: 1))

        #expect(waitlist.isEmpty)
        #expect(waitlist.contains(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Leaving one leaves the rest of the list alone")
    func removingOne() {
        let waitlist = Waitlist()
            .adding(item(1))
            .adding(item(2))
            .removing(productId: ProductID(rawValue: 1))

        #expect(waitlist.items.map(\.productId) == [ProductID(rawValue: 2)])
    }

    @Test("Leaving something never joined changes nothing")
    func removingWhatIsNotThere() {
        let waitlist = Waitlist().adding(item(1))

        #expect(waitlist.removing(productId: ProductID(rawValue: 9)) == waitlist)
    }

    @Test("Joining never changes the list it was joined on")
    func sideEffectFree() {
        let before = Waitlist().adding(item(1))
        _ = before.adding(item(2))

        #expect(before.itemCount == 1)
    }

    @Test("An item is identified by its product")
    func itemIdentity() {
        #expect(item(3).id == ProductID(rawValue: 3))
    }

    @Test("An item records when it was added")
    func itemRecordsWhen() {
        let when = Date(timeIntervalSince1970: 1_000)

        #expect(item(1, at: when).dateAdded == when)
    }

    @Test("Two waitlists holding the same items are the same")
    func equality() {
        let when = Date()
        #expect(Waitlist(items: [item(1, at: when)]) == Waitlist(items: [item(1, at: when)]))
        #expect(Waitlist(items: [item(1, at: when)]) != Waitlist(items: [item(2, at: when)]))
    }
}
