import Foundation
import Testing
import Product
@testable import StockAlert

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the alerts' own rules. The acceptance
/// suite says a shopper set an alert and cleared it; these say what the set does when they ask
/// twice, or clear one they never set.
@Suite("Stock alerts")
struct StockAlertsTests {
    private func item(_ id: Int, at date: Date = Date()) -> StockAlert {
        StockAlert(productId: ProductID(rawValue: id), dateAdded: date)
    }

    @Test("A shopper starts with no alerts")
    func empty() {
        #expect(StockAlerts().isEmpty)
        #expect(StockAlerts().itemCount == 0)
    }

    @Test("Asking adds an alert")
    func adding() {
        let stockAlerts = StockAlerts().adding(item(1))

        #expect(stockAlerts.contains(productId: ProductID(rawValue: 1)))
        #expect(stockAlerts.itemCount == 1)
    }

    @Test("Nothing is waited on until it is asked about")
    func notWaiting() {
        #expect(StockAlerts().contains(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Asking twice about the same thing is one alert")
    func askingTwice() {
        let stockAlerts = StockAlerts().adding(item(1)).adding(item(1))

        #expect(stockAlerts.itemCount == 1)
    }

    @Test("The newest comes first")
    func newestFirst() {
        let stockAlerts = StockAlerts(items: [
            item(1, at: .distantPast),
            item(2, at: .now)
        ])

        #expect(stockAlerts.items.map(\.productId) == [ProductID(rawValue: 2), ProductID(rawValue: 1)])
    }

    @Test("Building one from duplicates keeps one of each")
    func initialiserDeduplicates() {
        #expect(StockAlerts(items: [item(1), item(1), item(2)]).itemCount == 2)
    }

    @Test("Clearing an alert takes it off")
    func removing() {
        let stockAlerts = StockAlerts().adding(item(1)).removing(productId: ProductID(rawValue: 1))

        #expect(stockAlerts.isEmpty)
        #expect(stockAlerts.contains(productId: ProductID(rawValue: 1)) == false)
    }

    @Test("Clearing one leaves the rest alone")
    func removingOne() {
        let stockAlerts = StockAlerts()
            .adding(item(1))
            .adding(item(2))
            .removing(productId: ProductID(rawValue: 1))

        #expect(stockAlerts.items.map(\.productId) == [ProductID(rawValue: 2)])
    }

    @Test("Clearing one that was never set changes nothing")
    func removingWhatIsNotThere() {
        let stockAlerts = StockAlerts().adding(item(1))

        #expect(stockAlerts.removing(productId: ProductID(rawValue: 9)) == stockAlerts)
    }

    @Test("Asking never changes the alerts it was added to")
    func sideEffectFree() {
        let before = StockAlerts().adding(item(1))
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

    @Test("Two sets holding the same alerts are the same")
    func equality() {
        let when = Date()
        #expect(StockAlerts(items: [item(1, at: when)]) == StockAlerts(items: [item(1, at: when)]))
        #expect(StockAlerts(items: [item(1, at: when)]) != StockAlerts(items: [item(2, at: when)]))
    }
}
