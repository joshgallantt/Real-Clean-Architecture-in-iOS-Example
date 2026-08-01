import Foundation
import Testing
import Money
import Order
import Product
@testable import OrderUI

@MainActor
@Suite("Buying straight from a product page", .serialized)
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: Buy Now is the express path.
/// One product, one tap, and the bag is not part of it.
struct BuyingFromAProductPageTests {
    @Test("Tapping Buy Now buys that one product and shows the confirmation")
    func buyNow() async {
        let shopper = AShopper()
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.confirmed.count == 1)
        #expect(shopper.confirmed.first?.total == usd(9.99))
        #expect(shopper.orders.orders.count == 1)
    }

    @Test("Buy Now charges the price on the page, once")
    func chargesThePriceShown() async {
        let shopper = AShopper()
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 24.50))

        await button.tapAndSettle()

        #expect(shopper.till.amountsAskedFor == [usd(24.50)])
    }

    @Test("Buy Now leaves the bag alone — that is the whole point of it")
    func doesNotTouchTheBag() async {
        let shopper = AShopper()
        shopper.putInBag(2, at: 5)
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.bag.bag.items.map(\.productId) == [pid(2)])
    }

    @Test("A guest is asked to sign in, and the order goes through once they have")
    func guestIsAskedToSignIn() async {
        let shopper = AShopper()
        shopper.isSignedIn = false
        shopper.signIn.signsIn = true
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.signIn.timesAsked == 1)
        #expect(shopper.confirmed.count == 1)
    }

    @Test("A guest who backs out of signing in buys nothing and is not nagged")
    func guestWhoBacksOut() async {
        let shopper = AShopper()
        shopper.isSignedIn = false
        shopper.signIn.signsIn = false
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.confirmed.isEmpty)
        #expect(shopper.orders.orders.isEmpty)
        #expect(shopper.snackbars.shown.isEmpty)
    }

    @Test("A declined payment says so and leaves no order")
    func declined() async {
        let shopper = AShopper()
        shopper.till.outcome = .failure(.declined)
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.confirmed.isEmpty)
        #expect(shopper.orders.orders.isEmpty)
        #expect(shopper.snackbars.shown.first?.title == "Payment Declined")
    }

    @Test("A till that cannot be reached offers to try again")
    func unavailableOffersRetry() async {
        let shopper = AShopper()
        shopper.till.outcome = .failure(.unavailable)
        let button = shopper.buyNowButton(for: .fixture(id: 1, price: 9.99))

        await button.tapAndSettle()

        #expect(shopper.snackbars.shown.first?.title == "That Didn't Go Through")
        #expect(shopper.snackbars.shown.first?.action != nil)
    }
}
