import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
public protocol SettingsRepository: Sendable {
    @MainActor
    var settings: Settings { get }

    @MainActor
    var settingsPublisher: AnyPublisher<Settings, Never> { get }

    /// Throws when the change could not be kept, so a caller cannot report a change that did not
    /// happen. What is published is what was kept.
    @MainActor
    func save(_ settings: Settings) async throws
}
