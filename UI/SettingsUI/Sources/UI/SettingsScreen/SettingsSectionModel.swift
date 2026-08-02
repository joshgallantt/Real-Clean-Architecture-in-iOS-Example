import Settings

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: one `Form` section,
/// already worded and in the order the screen shows it — never a domain type extended with a title.
struct SettingsSectionModel: Identifiable, Equatable {
    let id: SettingsSection
    let title: String
    let rows: [SettingRow]
}
