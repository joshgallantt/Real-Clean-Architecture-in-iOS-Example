import Settings

/// The tracking plan for Settings: its screen and every element it reports, named once.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: a switch is reported by a
/// name of its own, not by its storage key and not by its label. The label is reworded as the
/// screen is; the key is renamed as the storage is; a report has to outlive both.
public enum SettingsTrackingPlan {
    public static let screen = "settings"

    /// Exhaustive, so a new setting cannot reach the screen without a name to be reported under.
    static func toggle(_ key: SettingKey, isOn: Bool) -> String {
        let name = switch key {
        case .pushNotifications: "push_notifications"
        case .bagChangesSection: "bag_changes_section"
        case .favoritesStockAlertsSection: "favorites_stock_alerts_section"
        }
        /// Which way it was left is part of the name: on and off are two decisions.
        return name + (isOn ? "_on" : "_off")
    }
}
