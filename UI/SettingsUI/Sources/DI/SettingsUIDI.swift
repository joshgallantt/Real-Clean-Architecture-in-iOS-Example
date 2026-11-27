import SwiftUI
import Settings
import SettingsUI
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct SettingsUIDI {
    private let observeOfferedSettings: ObserveOfferedSettingsUseCase
    private let setSetting: SetSettingUseCase
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        observeOfferedSettings: ObserveOfferedSettingsUseCase,
        setSetting: SetSettingUseCase,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.observeOfferedSettings = observeOfferedSettings
        self.setSetting = setSetting
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    @MainActor
    public func mainView() -> some View {
        SettingsScreenView(
            viewModel: SettingsScreenViewModel(
                observeOfferedSettings: observeOfferedSettings,
                setSetting: setSetting,
                trackScreenView: trackScreenView,
                trackElementInteraction: trackElementInteraction
            )
        )
        .trackingScreen(SettingsTrackingPlan.screen)
    }
}
