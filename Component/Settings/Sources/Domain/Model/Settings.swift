/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities, Value Objects, Services: no identity of
/// its own, so equality is by value. Ch. 10 — Side-Effect-Free Functions: `setting(_:to:)` answers
/// with a new `Settings` rather than mutating the one it was asked of.
///
/// Ch. 9 — Making Implicit Concepts Explicit: what a shopper has chosen, held against the key that
/// names it. It names no setting itself, so what each one is worth untouched stays with
/// `SettingKey`, and a write reaches the one key it was given rather than every key a caller
/// remembered to carry forward.
public struct Settings: Equatable, Sendable {
    private let values: [SettingKey: Bool]

    /// Every key holds a value from here on, chosen or not, so two records of the same choices are
    /// the same record however they were built.
    public init(_ chosen: [SettingKey: Bool] = [:]) {
        values = SettingKey.allCases.reduce(into: [:]) { values, key in
            values[key] = chosen[key] ?? key.defaultValue
        }
    }

    public func value(for key: SettingKey) -> Bool {
        values[key] ?? key.defaultValue
    }

    public func setting(_ key: SettingKey, to isOn: Bool) -> Settings {
        var chosen = values
        chosen[key] = isOn
        return Settings(chosen)
    }
}
