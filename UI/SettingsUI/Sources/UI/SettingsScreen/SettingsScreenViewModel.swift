import Combine
import Foundation
import Settings
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything. Which settings a shopper is offered is not one of them —
/// it is handed the ones they are offered, and decides only their wording and their order.
public final class SettingsScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var sections: [SettingsSectionModel] = []

    private let observeOfferedSettings: ObserveOfferedSettingsUseCase
    private let setSetting: SetSettingUseCase
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private var cancellables = Set<AnyCancellable>()

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

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeOfferedSettings()
            .sink { [weak self] settings in
                self?.show(settings)
            }
            .store(in: &cancellables)
    }

    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    /// Reported with the way it was left, because turning something off is the finding — the
    /// shopper is telling the shop which part of a screen is not worth having.
    func didToggle(_ key: SettingKey, to isOn: Bool, in context: TrackingContext) {
        trackElementInteraction(SettingsTrackingPlan.toggle(key, isOn: isOn), in: context)
        inFlight = Task { [setSetting] in
            await setSetting(key, isOn: isOn)
        }
    }

    private func show(_ settings: [Setting]) {
        sections = Self.sectionOrder.compactMap { section in
            let rows = settings
                .filter { $0.key.section == section }
                .map { SettingRow(id: $0.key, title: Self.title(for: $0.key), isOn: $0.isOn) }
            guard !rows.isEmpty else { return nil }
            return SettingsSectionModel(id: section, title: Self.title(for: section), rows: rows)
        }
    }

    // MARK: - Wording and order

    private static let sectionOrder: [SettingsSection] = [.notifications, .bag, .favorites]

    private static func title(for section: SettingsSection) -> String {
        switch section {
        case .notifications: "Notifications"
        case .bag: "Bag"
        case .favorites: "Favorites"
        }
    }

    private static func title(for key: SettingKey) -> String {
        switch key {
        case .pushNotifications: "Push Notifications"
        case .bagChangesSection: "Show Changes Since You Last Viewed"
        case .favoritesStockAlertsSection: "Show Stock Alerts"
        }
    }
}
