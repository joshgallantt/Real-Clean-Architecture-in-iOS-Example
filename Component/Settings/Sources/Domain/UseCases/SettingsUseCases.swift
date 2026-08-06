import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol ObserveOfferedSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<[Setting], Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Settings, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol SetSettingUseCase: Sendable {
    @MainActor
    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError>
}
