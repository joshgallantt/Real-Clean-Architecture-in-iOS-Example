/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities, Value Objects, Services: one setting as
/// a shopper meets it — which setting, and whether it is on. No identity of its own, so equality is
/// by value.
public struct Setting: Equatable, Sendable {
    public let key: SettingKey
    public let isOn: Bool

    public init(key: SettingKey, isOn: Bool) {
        self.key = key
        self.isOn = isOn
    }

    /// Evans, Ch. 10 — Side-Effect-Free Functions: the settings a shopper is offered, with the
    /// values their record holds. What they are not offered is not in the answer at all, so a caller
    /// cannot read a value it was never given.
    public static func offered(from settings: Settings, signedIn: Bool) -> [Setting] {
        SettingKey.offered(signedIn: signedIn)
            .map { Setting(key: $0, isOn: settings.value(for: $0)) }
    }
}
