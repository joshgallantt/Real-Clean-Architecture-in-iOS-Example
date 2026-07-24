import SwiftUI
import OnboardingUI

public struct OnboardingUIDI {
    public init() {}

    @MainActor
    public func onboardingView(onFinish: @escaping () -> Void) -> some View {
        OnboardingScreenView(onFinish: onFinish)
    }
}
