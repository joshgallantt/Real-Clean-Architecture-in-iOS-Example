import Foundation
import Testing
import Product
import Wishlist

/// Everything the wishlist decides, decided without a repository, a store or a catalog.
@Suite("What a wishlist holds")
struct WishlistTests {

    @Test("A new wishlist holds nothing")
    func empty() {
        let wishlist = Wishlist()

        #expect(wishlist.isEmpty)
        #expect(wishlist.itemCount == 0)
        #expect(!wishlist.contains(productId: pid(1)))
    }

    @Test("Saving something puts it in the list")
    func saving() {
        let wishlist = Wishlist().adding(WishlistItem(productId: pid(1)))

        #expect(wishlist.contains(productId: pid(1)))
        #expect(wishlist.itemCount == 1)
    }

    @Test("Saving something already saved changes nothing, and does not move it to the top")
    func savingTwice() {
        let firstSaved = WishlistItem(productId: pid(1), dateAdded: .distantPast)
        let wishlist = Wishlist()
            .adding(firstSaved)
            .adding(WishlistItem(productId: pid(2), dateAdded: .now))

        let again = wishlist.adding(WishlistItem(productId: pid(1), dateAdded: .now))

        #expect(again == wishlist)
        #expect(again.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("The most recently saved sits at the top")
    func newestFirst() {
        let wishlist = Wishlist()
            .adding(WishlistItem(productId: pid(1), dateAdded: .distantPast))
            .adding(WishlistItem(productId: pid(2), dateAdded: .now))

        #expect(wishlist.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("A list handed its entries in any order still holds them newest first")
    func ordersWhateverItIsGiven() {
        let older = WishlistItem(productId: pid(1), dateAdded: .distantPast)
        let newer = WishlistItem(productId: pid(2), dateAdded: .now)

        #expect(Wishlist(items: [older, newer]).items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Removing something takes it out and leaves the rest")
    func removing() {
        let wishlist = Wishlist()
            .adding(WishlistItem(productId: pid(1)))
            .adding(WishlistItem(productId: pid(2)))

        #expect(wishlist.removing(productId: pid(1)).items.map(\.id) == [pid(2)])
    }

    @Test("Removing something that was never saved changes nothing")
    func removingSomethingAbsent() {
        let wishlist = Wishlist().adding(WishlistItem(productId: pid(1)))

        #expect(wishlist.removing(productId: pid(99)) == wishlist)
    }
}
