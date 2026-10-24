import Session
import Settings

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SettingsStore: Sendable {
    func getSettings(for session: Session) -> Settings

    /// Throws when the change could not be kept. What went wrong is the store's business; that it
    /// did not happen is the domain's.
    func setSettings(_ settings: Settings, for session: Session) async throws
}
