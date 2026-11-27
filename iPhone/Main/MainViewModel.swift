import Foundation
import Session
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
final class MainViewModel {
    enum Phase: Hashable {
        case splash
        case welcome
        case onboarding
        case main
    }

    private(set) var phase: Phase = .splash

    private let getSession: GetSessionUseCase
    private let requestTrackingConsent: RequestTrackingConsentUseCase

    private let splashDuration: Duration = .seconds(1.2)

    private let settleAfterAuthentication: Duration = .milliseconds(500)

    init(getSession: GetSessionUseCase, requestTrackingConsent: RequestTrackingConsentUseCase) {
        self.getSession = getSession
        self.requestTrackingConsent = requestTrackingConsent
    }

    func onAppear() async {
        guard phase == .splash else { return }
        try? await Task.sleep(for: splashDuration)
        guard phase == .splash else { return }
        if getSession().isLoggedIn { enterTheShop() } else { phase = .welcome }
    }

    func continueAsGuest() {
        enterTheShop()
    }

    func authenticationFinished() {
        Task {
            try? await Task.sleep(for: settleAfterAuthentication)
            enterTheShop()
        }
    }

    /// The App Tracking Transparency prompt is asked for here, once the shop is on screen — not at
    /// launch, where the splash would hide what the person is being asked about, and where the system
    /// refuses to show it before the app is active. After the first answer, asking again is silent.
    private func enterTheShop() {
        phase = .main
        Task { await requestTrackingConsent() }
    }
}
