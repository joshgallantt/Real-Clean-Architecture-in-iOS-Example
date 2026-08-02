import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol SetSettingUseCase: Sendable {
    @MainActor
    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: requiring a signed-in shopper for a
/// favorites setting is not something the aggregate can decide for itself — it needs the session —
/// so supplying the session is the use case's job. What is refused is exactly what
/// `SettingKey.offered(signedIn:)` leaves out, which is also all a screen is ever handed.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both.
public struct DefaultSetSettingUseCase: SetSettingUseCase {
    private let repository: SettingsRepository
    private let getSession: GetSessionUseCase

    public init(repository: SettingsRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    public func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        guard SettingKey.offered(signedIn: getSession().isLoggedIn).contains(key) else {
            return .failure(.unauthenticated)
        }

        do {
            try await repository.save(repository.settings.setting(key, to: isOn))
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
