import Foundation
import Testing
import Product
@testable import StockAlert

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the waitlist's own rules. The acceptance
/// suite says a shopper was told something came back; these say what the list does when they ask
/// twice, or change their mind about something they never asked about.
@Suite("StockAlerts")
struct StockAlertsTests {
    private func alert(_ id: Int, at date: Date = Date()) -> StockAlert {
        StockAlert(productId: ProductID(rawValue: id), dateAsked: date)
    }

    @Test("A new waitlist is empty")
    func empty() {
        #expect(StockAlerts().isEmpty)
        #expect(StockAlerts().count == 0)
    }

    @Test("Asking puts it on the list")
    func adding() {
        let alerts = StockAlerts().adding(alert(1))

        #expect(alerts.waitingFor(productId: ProductID(rawValue: 1)))
        #expect(alerts.count == 1)
    }

    @Test("Nothing is waited on until it is asked for")
    func notWaiting() {
        #expect(StockAlerts().waitingFor(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Asking twice about the same thing is one ask")
    func askingTwice() {
        let alerts = StockAlerts().adding(alert(1)).adding(alert(1))

        #expect(alerts.count == 1)
    }

    @Test("The newest ask comes first")
    func newestFirst() {
        let alerts = StockAlerts(alerts: [
            alert(1, at: .distantPast),
            alert(2, at: .now)
        ])

        #expect(alerts.alerts.map(\.productId) == [ProductID(rawValue: 2), ProductID(rawValue: 1)])
    }

    @Test("Building one from duplicates keeps one of each")
    func initialiserDeduplicates() {
        #expect(StockAlerts(alerts: [alert(1), alert(1), alert(2)]).count == 2)
    }

    @Test("Changing their mind takes it off")
    func removing() {
        let alerts = StockAlerts().adding(alert(1)).removing(productId: ProductID(rawValue: 1))

        #expect(alerts.isEmpty)
        #expect(alerts.waitingFor(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Removing leaves the rest of the list alone")
    func removingOne() {
        let alerts = StockAlerts()
            .adding(alert(1))
            .adding(alert(2))
            .removing(productId: ProductID(rawValue: 1))

        #expect(alerts.alerts.map(\.productId) == [ProductID(rawValue: 2)])
    }

    @Test("Removing something never asked about changes nothing")
    func removingWhatIsNotThere() {
        let alerts = StockAlerts().adding(alert(1))

        #expect(alerts.removing(productId: ProductID(rawValue: 9)) == alerts)
    }

    @Test("Asking never changes the list it was asked of")
    func sideEffectFree() {
        let before = StockAlerts().adding(alert(1))
        _ = before.adding(alert(2))

        #expect(before.count == 1)
    }

    @Test("An ask is identified by its product")
    func alertIdentity() {
        #expect(alert(3).id == ProductID(rawValue: 3))
    }

    @Test("An ask records when it was made")
    func alertRecordsWhen() {
        let when = Date(timeIntervalSince1970: 1_000)

        #expect(alert(1, at: when).dateAsked == when)
    }

    @Test("Two waitlists holding the same asks are the same")
    func equality() {
        let when = Date()
        #expect(StockAlerts(alerts: [alert(1, at: when)]) == StockAlerts(alerts: [alert(1, at: when)]))
        #expect(StockAlerts(alerts: [alert(1, at: when)]) != StockAlerts(alerts: [alert(2, at: when)]))
    }
}
