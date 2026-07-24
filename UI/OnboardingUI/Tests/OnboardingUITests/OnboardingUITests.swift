import XCTest
@testable import OnboardingUI

final class OnboardingUITests: XCTestCase {
    @MainActor
    func test_view_initialises() {
        _ = OnboardingScreenView(onFinish: {})
    }
}
