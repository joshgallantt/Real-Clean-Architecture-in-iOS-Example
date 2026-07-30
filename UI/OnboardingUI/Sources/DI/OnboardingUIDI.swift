import SwiftUI
import OnboardingUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy. Onboarding asks the domain nothing, so it is handed nothing — the container exists so
/// the composition root builds every feature the same way.
public struct OnboardingUIDI {
    public init() {}

    @MainActor
    public func onboardingView(onFinish: @escaping () -> Void) -> some View {
        OnboardingScreenView(onFinish: onFinish)
    }
}
