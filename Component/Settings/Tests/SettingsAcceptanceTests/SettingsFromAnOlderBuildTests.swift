import Foundation
import Testing
import Settings

@MainActor
@Suite("Settings kept by an older build")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: through real JSON on a real
/// disk, because only that can say what a file written before a setting was withdrawn does to the
/// shopper who still has one.
struct SettingsFromAnOlderBuildTests {
    @Test("Settings this build no longer has are passed over, and the ones it still has are kept")
    func withdrawnSettingsArePassedOver() throws {
        let directory = URL.newTemporaryDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try """
        {
          "values": {
            "pushNotifications": true,
            "bagOutOfStockNotice": false,
            "bagPriceIncreases": false,
            "bagPriceDecreases": false,
            "favoritesWaitlistSection": false,
            "favoritesBackInStockSection": false
          }
        }
        """.write(to: directory.appending(path: "42.json"), atomically: true, encoding: .utf8)

        let shopper = Shopper(in: directory, signedInAs: 42)

        #expect(shopper.isOn(.pushNotifications) == true)
        #expect(shopper.isOn(.bagChangesSection) == true)
        #expect(shopper.isOn(.favoritesStockAlertsSection) == true)
    }
}
