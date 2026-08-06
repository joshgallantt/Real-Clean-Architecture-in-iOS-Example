import Foundation
import Testing
import Settings

@MainActor
@Suite("When a setting cannot be kept")
/// The shopper is not told which layer failed, because they cannot act on that. They are told the
/// change did not happen, which they can.
struct WhenASettingCannotBeKeptTests {
    // SettingsMenu-11: A change that could not be written is reported, not quietly forgotten.
    @Test("A change that could not be written is reported, not quietly forgotten")
    func changeFails() async throws {
        let shopper = Shopper(in: try .unwritableDirectory())

        #expect(await shopper.turn(.pushNotifications, true).failure == .unavailable)
    }

    // SettingsMenu-12: A setting that could not be kept does not appear as though it was changed.
    @Test("A setting that could not be kept does not appear as though it was changed")
    func theSettingDoesNotPretend() async throws {
        let shopper = Shopper(in: try .unwritableDirectory())

        await shopper.turn(.pushNotifications, true)

        #expect(shopper.isOn(.pushNotifications) == false)
    }

    // SettingsMenu-13: Not being signed in and not being able to save are different answers.
    @Test("Not being signed in and not being able to save are different answers")
    func differentAnswers() async throws {
        let guest = Shopper(in: try .unwritableDirectory())
        let shopper = Shopper(in: try .unwritableDirectory(), signedInAs: 42)

        #expect(await guest.turn(.favoritesWaitlistSection, false).failure == .unauthenticated)
        #expect(await shopper.turn(.pushNotifications, true).failure == .unavailable)
    }
}
