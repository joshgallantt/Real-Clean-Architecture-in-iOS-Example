import Foundation
import ProductTestSupport
import Testing
import Product
import StockAlert

@MainActor
@Suite("Keeping a stock alert")
/// The modelling decision, asserted rather than assumed. An alert is wanting to be told; whether
/// the shop has any is a fact about the shop. So no alert is cleared on the shopper's behalf, and
/// something that sells out again is waited on again without their asking twice.
struct KeepingAStockAlertTests {
    @Test("Something that comes back keeps its alert — it is only shown as back")
    func keepsItsAlertWhenBack() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)

        shopper.theShopSells(inStock(1))

        #expect(await shopper.shownAsBack() == [pid(1)])
        #expect(shopper.stockAlerts.contains(productId: pid(1)))
    }

    @Test("Something that sells out again is waited on again, with nobody asked to set the alert twice")
    func sellsOutAgain() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)
        shopper.theShopSells(inStock(1))
        #expect(await shopper.shownAsBack() == [pid(1)])

        shopper.theShopSells(soldOut(1))

        #expect(await shopper.shownAsSoldOut() == [pid(1)])
        #expect(await shopper.shownAsBack() == [])
    }

    @Test("Turning the alert off stops it being shown, back or not")
    func turningItOff() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.setAlert(productId: 1)
        shopper.theShopSells(inStock(1))

        await shopper.clearAlert(productId: 1)

        #expect(await shopper.shownAsSoldOut() == [])
        #expect(await shopper.shownAsBack() == [])
        #expect(shopper.stockAlerts.isEmpty)
    }

    @Test("The bell follows the alert, not the shelf")
    func theBellFollowsTheAlert() async {
        let shopper = Shopper(signedInAs: 1)
        shopper.watchTheBell(onProductId: 1)
        shopper.theShopSells(inStock(1))

        await shopper.setAlert(productId: 1)
        #expect(shopper.bellIsOn[pid(1)] == true)

        await shopper.clearAlert(productId: 1)
        #expect(shopper.bellIsOn[pid(1)] == false)
    }
}
