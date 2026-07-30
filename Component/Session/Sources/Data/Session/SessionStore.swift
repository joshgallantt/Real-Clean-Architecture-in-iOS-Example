import Foundation
import Combine
import Session

@MainActor
/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SessionStore: AnyObject, Sendable {
    var session: Session { get }
    var sessionPublisher: AnyPublisher<Session, Never> { get }
    var authToken: AuthToken? { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}

@MainActor
public final class DefaultSessionStore: SessionStore {
    public private(set) var authToken: AuthToken?
    private var expiryTask: Task<Void, Never>?
    private let sessionSubject: CurrentValueSubject<Session, Never>
    private let defaults: UserDefaults
    private let storageKey = "session.current"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let restored = Self.loadSnapshot(from: defaults, key: storageKey), !restored.token.isExpired {
            self.authToken = restored.token
            self.sessionSubject = CurrentValueSubject(.authenticated(restored.user))
        } else {
            self.authToken = nil
            self.sessionSubject = CurrentValueSubject(.guest)
            defaults.removeObject(forKey: storageKey)
        }

        if let token = authToken {
            scheduleExpiry(for: token)
        }
    }

    public var session: Session {
        sessionSubject.value
    }

    public var sessionPublisher: AnyPublisher<Session, Never> {
        sessionSubject.eraseToAnyPublisher()
    }

    public func setUser(_ user: User, token: AuthToken) {
        self.authToken = token
        sessionSubject.send(.authenticated(user))
        saveSnapshot(user: user, token: token)
        scheduleExpiry(for: token)
    }

    public func clear() {
        self.authToken = nil
        sessionSubject.send(.guest)
        defaults.removeObject(forKey: storageKey)
        cancelExpiryTask()
    }

    private func saveSnapshot(user: User, token: AuthToken) {
        let snapshot = SessionSnapshotDTO(
            user: .init(
                id: user.id.rawValue,
                email: user.email.value,
                firstName: user.name.first,
                lastName: user.name.last ?? ""
            ),
            tokenValue: token.value,
            expiresAt: token.expiresAt
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadSnapshot(from defaults: UserDefaults, key: String) -> (user: User, token: AuthToken)? {
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(SessionSnapshotDTO.self, from: data)
        else {
            return nil
        }
        let user = User(
            id: UserID(rawValue: snapshot.user.id),
            email: Email(snapshot.user.email),
            name: PersonName(first: snapshot.user.firstName, last: snapshot.user.lastName)
        )
        let token = AuthToken(value: snapshot.tokenValue, expiresAt: snapshot.expiresAt)
        return (user, token)
    }

    private func scheduleExpiry(for token: AuthToken) {
        cancelExpiryTask()
        let interval = token.expiresAt.timeIntervalSinceNow
        guard interval > 0 else {
            clear()
            return
        }
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            self?.clear()
        }
    }

    private func cancelExpiryTask() {
        expiryTask?.cancel()
        expiryTask = nil
    }
}
