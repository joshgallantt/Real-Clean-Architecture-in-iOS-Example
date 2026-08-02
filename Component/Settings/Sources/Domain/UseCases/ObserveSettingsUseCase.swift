import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Settings, Never>
}

public struct DefaultObserveSettingsUseCase: ObserveSettingsUseCase {
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Settings, Never> {
        repository.settingsPublisher
    }
}
