import Foundation
import ProductTestSupport
import Testing
import StockAlert

@MainActor
@Suite("Asking for a stock alert")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct AskingForAStockAlertTests {
    @Test("A shopper asks to be told about something, and the bell says they did")
    func asks() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.setAlert(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == true)
    }

    @Test("A shopper who has asked about nothing is waiting on nothing")
    func nothingAskedYet() {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Asking twice is one alert — nobody wants telling twice")
    func askingTwice() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)

        await shopper.setAlert(productId: 1)
        await shopper.setAlert(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == true)
        #expect(shopper.stockAlerts.itemCount == 1)
    }

    @Test("A shopper who turns an alert off no longer has it")
    func turnsItOff() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.setAlert(productId: 1)

        await shopper.clearAlert(productId: 1)

        #expect(shopper.bellIsOn[pid(1)] == false)
    }

    @Test("Turning off an alert they never set changes nothing, and is not an error")
    func turningOffWhatWasNeverSet() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 1)
        await shopper.setAlert(productId: 1)

        #expect(await shopper.clearAlert(productId: 99).failure == nil)
        #expect(shopper.bellIsOn[pid(1)] == true)
    }

    @Test("The bell on one product ignores what the shopper does with others")
    func theBellFollowsOneProduct() async {
        let shopper = Shopper(signedInAs: 42)
        shopper.watchTheBell(onProductId: 7)
        await shopper.setAlert(productId: 7)

        await shopper.setAlert(productId: 99)
        await shopper.clearAlert(productId: 99)

        #expect(shopper.bellIsOn[pid(7)] == true)
    }

    @Test("The alerts are still there when the shopper comes back")
    func survivesLeaving() async {
        let shopper = Shopper(signedInAs: 42)
        await shopper.setAlert(productId: 1)

        let returning = shopper.leaveAndComeBack()
        returning.watchTheBell(onProductId: 1)

        #expect(returning.bellIsOn[pid(1)] == true)
    }

    @Test("Alerts kept in the first shape they were written in are carried forward, and only once")
    func carriesTheOldListForward() async throws {
        let legacy = URL.newTemporaryDirectory
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data(#"[{"productId":1,"dateAsked":0}]"#.utf8).write(to: legacy.appending(path: "42.json"))

        let shopper = Shopper(legacyDirectory: legacy, signedInAs: 42)

        #expect(shopper.stockAlerts.contains(productId: pid(1)))
        #expect(!FileManager.default.fileExists(atPath: legacy.appending(path: "42.json").path()))
        #expect(shopper.leaveAndComeBack().stockAlerts.contains(productId: pid(1)))
    }
}
