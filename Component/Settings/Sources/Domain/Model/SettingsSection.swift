/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the three groupings a shopper
/// already sees the settings screen in, named once so `SettingKey` and the screen that renders it
/// agree on what a section is.
public enum SettingsSection: CaseIterable, Equatable, Hashable, Sendable {
    case notifications
    case bag
    case favorites
}
