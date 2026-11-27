import Foundation
import ProductTestSupport
import Testing
import StockAlert

@MainActor
@Suite("When a stock alert cannot be kept")
struct WhenAStockAlertCannotBeKeptTests {
    @Test("An alert that could not be written down is reported, not quietly forgotten")
    func settingFails() async throws {
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await shopper.setAlert(productId: 1).failure == .unavailable)
    }

    @Test("The bell does not light up for an alert nobody recorded")
    func theBellDoesNotPretend() async throws {
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.setAlert(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Not being signed in and not being able to keep the alert are different answers")
    func differentAnswers() async throws {
        let guest = Shopper(in: try .unwritableDirectory())
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await guest.setAlert(productId: 1).failure == .unauthenticated)
        #expect(await shopper.setAlert(productId: 1).failure == .unavailable)
    }
}
