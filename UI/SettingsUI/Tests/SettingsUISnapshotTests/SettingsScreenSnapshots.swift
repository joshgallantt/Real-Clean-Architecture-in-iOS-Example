import Settings
import SettingsTestSupport
import SnapshotTesting
import SwiftUI
import Testing
@testable import SettingsUI

/// The doubles come from a TestSupport module rather than a second copy here.
/// Xcode refuses a test target that depends on another test target, so code two
/// suites both need has to be an ordinary module; `@testable` reaches its
/// internal types, so nothing had to be made public to share it.
@MainActor
@Test("The settings screen lists every setting with its switch")
func theSettingsScreenListsEverySetting() {
    let screen = SettingsScreenView(
        viewModel: SettingsScreenViewModel(
            observeOfferedSettings: StubObserveOfferedSettings([
                Setting(key: .pushNotifications, isOn: true),
                Setting(key: .bagOutOfStockNotice, isOn: false),
                Setting(key: .bagPriceDecreases, isOn: true)
            ]),
            setSetting: SpySetSetting()
        )
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}

@MainActor
@Test("A settings screen with nothing to offer still renders its frame")
func anEmptySettingsScreenStillRenders() {
    let screen = SettingsScreenView(
        viewModel: SettingsScreenViewModel(
            observeOfferedSettings: StubObserveOfferedSettings(),
            setSetting: SpySetSetting()
        )
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
