import Foundation
import Testing
import Money
import Order
import Product
@testable import OrderUI

@MainActor
@Suite("Checking out the bag", .serialized)
struct CheckingOutTheBagTests {
    @Test("Checking out buys everything in the bag, at the prices the bag was showing")
    func buysTheWholeBag() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 2, at: 9.99)
        shopper.putInBag(2, at: 5)
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.till.amountsAskedFor == [usd(24.98)])
        #expect(shopper.confirmed.first?.total == usd(24.98))
        #expect(shopper.confirmed.first?.itemCount == 3)
    }

    @Test("A bag that has been checked out is empty afterwards")
    func emptiesTheBag() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.bag.bag.isEmpty)
    }

    @Test("A declined payment leaves the bag exactly as it was")
    func declinedKeepsTheBag() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 2, at: 9.99)
        shopper.till.outcome = .failure(.declined)
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.bag.bag.quantity(of: pid(1)) == 2)
        #expect(shopper.orders.orders.isEmpty)
        #expect(shopper.snackbars.shown.first?.title == "Payment Declined")
    }

    @Test("A till that cannot be reached leaves the bag alone too")
    func unavailableKeepsTheBag() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        shopper.till.outcome = .failure(.unavailable)
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.bag.bag.isEmpty == false)
    }

    @Test("The button says what it is about to charge")
    func showsTheTotal() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 2, at: 10)
        let button = shopper.checkoutButton()

        await Task.yield()

        #expect(button.totalLabel == usd(20).formatted())
        #expect(button.isEmpty == false)
    }

    @Test("An empty bag has nothing to check out")
    func emptyBag() async {
        let shopper = AShopper()
        let button = shopper.checkoutButton()

        await Task.yield()

        #expect(button.isEmpty)
    }

    @Test("A guest is asked to sign in, and the bag survives them backing out")
    func guestWhoBacksOutKeepsTheirBag() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        shopper.isSignedIn = false
        shopper.signIn.signsIn = false
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.signIn.timesAsked == 1)
        #expect(shopper.bag.bag.isEmpty == false)
        #expect(shopper.orders.orders.isEmpty)
    }
}

@MainActor
extension CheckoutButtonViewModel {
    /// The tap a shopper makes, and the wait a test has to do because the button does not.
    func tapAndSettle() async {
        didTap()
        for _ in 0..<50 { await Task.yield() }
    }
}

@MainActor
extension BuyNowButtonViewModel {
    func tapAndSettle() async {
        didTap()
        for _ in 0..<50 { await Task.yield() }
    }
}
