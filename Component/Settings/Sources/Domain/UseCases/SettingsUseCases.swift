import Combine

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their settings. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

/// The only way out of this component for what a shopper has chosen, and it answers in the settings
/// they are offered rather than the record behind them. A guest and a signed-in shopper are asked
/// the same question and told different things, which is the rule rather than a caller's business
/// to apply. Nothing outside here needs the whole record, and publishing it would be publishing a
/// value for a key the shopper was never offered — the thing `Setting.offered(from:signedIn:)`
/// exists to make unreachable.
public protocol ObserveOfferedSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<[Setting], Never>
}

public protocol SetSettingUseCase: Sendable {
    @MainActor
    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError>
}
