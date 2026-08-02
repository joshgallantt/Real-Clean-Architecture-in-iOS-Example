import Settings

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a row already worded
/// for the screen. `SettingsScreenViewModel` maps to it; the view moves it onto a `Toggle` without
/// processing it further.
struct SettingRow: Identifiable, Equatable {
    let id: SettingKey
    let title: String
    let isOn: Bool
}
