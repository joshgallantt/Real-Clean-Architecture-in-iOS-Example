import SnapshotTesting
import SwiftUI
import Testing
@testable import OnboardingUI

/// What a screen looks like is the one thing neither other tier can check. An
/// acceptance test says the shopper got where they were going; a unit test says
/// the rule was right; neither notices that the button has fallen off the
/// bottom of the screen.
///
/// The recorded images are committed. Without them the suite writes its
/// reference on every run and compares it against itself, so it passes forever
/// and has never once been able to fail.
@MainActor
@Test("The onboarding screen offers a way to continue")
func onboardingScreenOffersAWayToContinue() {
    let screen = OnboardingScreenView(onFinish: {})

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
