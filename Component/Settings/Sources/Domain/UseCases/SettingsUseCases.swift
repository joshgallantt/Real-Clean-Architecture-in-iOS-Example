import Combine

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their settings. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

public protocol ObserveOfferedSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<[Setting], Never>
}

public protocol ObserveSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Settings, Never>
}

public protocol SetSettingUseCase: Sendable {
    @MainActor
    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError>
}
