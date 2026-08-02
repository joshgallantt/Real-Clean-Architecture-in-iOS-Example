import Combine
import Foundation
import Settings

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything. Which settings a shopper is offered is not one of them —
/// it is handed the ones they are offered, and decides only their wording and their order.
public final class SettingsScreenViewModel: ObservableObject {
    @Published private(set) var sections: [SettingsSectionModel] = []

    private let observeOfferedSettings: ObserveOfferedSettingsUseCase
    private let setSetting: SetSettingUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(
        observeOfferedSettings: ObserveOfferedSettingsUseCase,
        setSetting: SetSettingUseCase
    ) {
        self.observeOfferedSettings = observeOfferedSettings
        self.setSetting = setSetting
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeOfferedSettings()
            .sink { [weak self] settings in
                self?.show(settings)
            }
            .store(in: &cancellables)
    }

    func didToggle(_ key: SettingKey, to isOn: Bool) {
        Task { [setSetting] in
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
        case .bagOutOfStockNotice: "Show Out-of-Stock Notice"
        case .bagPriceIncreases: "Show Price Increases"
        case .bagPriceDecreases: "Show Price Decreases"
        case .favoritesWaitlistSection: "Show Waitlist"
        case .favoritesBackInStockSection: "Show Back in Stock"
        }
    }
}
