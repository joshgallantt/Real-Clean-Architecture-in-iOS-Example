import Foundation
import Testing
import Product
@testable import Wishlist

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the aggregate's own rules, stated one at a
/// time. The acceptance suite says a shopper saved something; these say what saving the same thing
/// twice does.
@Suite("Wishlist")
struct WishlistTests {
    private func item(_ id: Int, at date: Date = Date()) -> WishlistItem {
        WishlistItem(productId: ProductID(rawValue: id), dateAdded: date)
    }

    @Test("A new wishlist is empty")
    func empty() {
        #expect(Wishlist().isEmpty)
        #expect(Wishlist().itemCount == 0)
    }

    @Test("Saving something puts it on the list")
    func adding() {
        let list = Wishlist().adding(item(1))

        #expect(list.contains(productId: ProductID(rawValue: 1)))
        #expect(list.itemCount == 1)
    }

    @Test("A list does not contain what was never saved")
    func doesNotContain() {
        #expect(Wishlist().contains(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Saving the same thing twice saves it once")
    func addingTwice() {
        let list = Wishlist().adding(item(1)).adding(item(1))

        #expect(list.itemCount == 1)
    }

    @Test("The newest save comes first")
    func newestFirst() {
        let list = Wishlist(items: [
            item(1, at: .distantPast),
            item(2, at: .now)
        ])

        #expect(list.items.map(\.productId) == [ProductID(rawValue: 2), ProductID(rawValue: 1)])
    }

    @Test("Building one from duplicates keeps one of each")
    func initialiserDeduplicates() {
        let list = Wishlist(items: [item(1), item(1), item(2)])

        #expect(list.itemCount == 2)
    }

    @Test("Removing takes it off")
    func removing() {
        let list = Wishlist().adding(item(1)).removing(productId: ProductID(rawValue: 1))

        #expect(list.isEmpty)
    }

    @Test("Removing leaves everything else alone")
    func removingOne() {
        let list = Wishlist()
            .adding(item(1))
            .adding(item(2))
            .removing(productId: ProductID(rawValue: 1))

        #expect(list.items.map(\.productId) == [ProductID(rawValue: 2)])
    }

    @Test("Removing something that was never saved changes nothing")
    func removingWhatIsNotThere() {
        let list = Wishlist().adding(item(1))

        #expect(list.removing(productId: ProductID(rawValue: 9)) == list)
    }

    @Test("Saving never changes the list it was asked of")
    func sideEffectFree() {
        let before = Wishlist().adding(item(1))
        _ = before.adding(item(2))

        #expect(before.itemCount == 1)
    }

    @Test("A saved item is identified by its product")
    func itemIdentity() {
        #expect(item(3).id == ProductID(rawValue: 3))
    }

    @Test("Two lists holding the same things are the same")
    func equality() {
        let when = Date()
        #expect(Wishlist(items: [item(1, at: when)]) == Wishlist(items: [item(1, at: when)]))
        #expect(Wishlist(items: [item(1, at: when)]) != Wishlist(items: [item(2, at: when)]))
    }
}
