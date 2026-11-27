import MoneyTestSupport
import Foundation
import ProductTestSupport
import Testing
import Money
import Order
import Product
@testable import OrderUI
@testable import OrderUITestSupport

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

    // MARK: - A bag the shop has changed since it was kept

    @Test("A shopper whose bag holds something that got dearer is charged the price they were shown")
    func chargedThePriceShown() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 2, at: 9.99)
        shopper.theShopNowSells(.fixture(id: 1, price: 12.99))
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        #expect(button.totalLabel == usd(25.98).formatted())
        await button.tapAndSettle()

        #expect(shopper.till.amountsAskedFor == [usd(25.98)])
        #expect(shopper.confirmed.first?.lines == [OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(12.99))])
    }

    @Test("Something the shop has sold out of is not ordered, and the rest of the bag still is")
    func soldOutIsNotOrdered() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        shopper.putInBag(2, at: 5)
        shopper.theShopNowSells(.fixture(id: 1, price: 9.99), .fixture(id: 2, price: 5, availability: .outOfStock))
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.till.amountsAskedFor == [usd(9.99)])
        #expect(shopper.confirmed.first?.lines.map(\.productId) == [pid(1)])
    }

    @Test("No more of anything is ordered than the shop has left")
    func onlyWhatIsLeftIsOrdered() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 5, at: 10)
        shopper.theShopNowSells(.fixture(id: 1, price: 10, availability: .inStock(remaining: 2)))
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.till.amountsAskedFor == [usd(20)])
        #expect(shopper.confirmed.first?.itemCount == 2)
    }

    @Test("Nothing the shop changed blocks the checkout while there is still something to buy")
    func changesDoNotBlockTheCheckout() async {
        let shopper = AShopper()
        shopper.putInBag(1, quantity: 5, at: 9.99)
        shopper.putInBag(2, at: 5)
        shopper.theShopNowSells(
            .fixture(id: 1, price: 12.99, availability: .inStock(remaining: 1)),
            .fixture(id: 2, availability: .outOfStock)
        )
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        #expect(button.isEmpty == false)
        await button.tapAndSettle()

        #expect(shopper.confirmed.count == 1)
    }

    @Test("A bag holding only what has sold out has nothing to check out")
    func nothingLeftToBuy() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        shopper.theShopNowSells(.fixture(id: 1, availability: .outOfStock))
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        #expect(button.isEmpty)
    }

    @Test("What was bought is out of the bag afterwards, whatever price it had been kept at")
    func emptiesWhatWasBought() async {
        let shopper = AShopper()
        shopper.putInBag(1, at: 9.99)
        shopper.theShopNowSells(.fixture(id: 1, price: 12.99))
        await shopper.looksInTheirBag()
        let button = shopper.checkoutButton()

        await button.tapAndSettle()

        #expect(shopper.bag.bag.isEmpty)
        #expect(button.isEmpty)
    }

    // MARK: -

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
