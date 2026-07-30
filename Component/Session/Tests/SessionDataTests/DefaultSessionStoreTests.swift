import Foundation
import Testing
import Session
@testable import SessionData

@MainActor
@Suite("Staying signed in")
/// Fowler, *PoEAA* (2002) — Repository: the translation and the keeping, tested with the real
/// implementation over a stubbed gateway. No rule about what the domain means lives at this level.
struct DefaultSessionStoreTests {
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "session.tests.\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.description)
        return defaults
    }

    @Test("A shopper who has not signed in is a guest")
    func startsAsGuest() {
        let store = DefaultSessionStore(defaults: makeDefaults())

        #expect(store.session == .guest)
        #expect(store.authToken == nil)
    }

    @Test("Signing in is remembered for the next launch")
    func sessionSurvivesRelaunch() {
        let defaults = makeDefaults()
        DefaultSessionStore(defaults: defaults)
            .setUser(.fixture(), token: .fixture(expiresIn: 3600))

        let nextLaunch = DefaultSessionStore(defaults: defaults)

        #expect(nextLaunch.session.user?.email == Email("shopper@example.com"))
        #expect(nextLaunch.authToken?.value == "token")
    }

    @Test("A token that expired while the app was closed is not a session")
    func expiredTokenIsNotRestored() {
        let defaults = makeDefaults()
        DefaultSessionStore(defaults: defaults)
            .setUser(.fixture(), token: .fixture(expiresIn: -1))

        let nextLaunch = DefaultSessionStore(defaults: defaults)

        #expect(nextLaunch.session == .guest)
        #expect(nextLaunch.authToken == nil)
    }

    @Test("An expired session is forgotten rather than left on disk to be tried again")
    func expiredSessionIsCleanedUp() {
        let defaults = makeDefaults()
        DefaultSessionStore(defaults: defaults)
            .setUser(.fixture(), token: .fixture(expiresIn: -1))

        _ = DefaultSessionStore(defaults: defaults)

        #expect(defaults.data(forKey: "session.current") == nil)
    }

    @Test("A token that is already past its expiry never counts as signed in")
    func alreadyExpiredTokenIsRefused() {
        let store = DefaultSessionStore(defaults: makeDefaults())

        store.setUser(.fixture(), token: .fixture(expiresIn: -1))

        #expect(store.session == .guest)
        #expect(store.authToken == nil)
    }

    @Test("Signing out forgets the shopper immediately and for the next launch")
    func signOutIsRemembered() {
        let defaults = makeDefaults()
        let store = DefaultSessionStore(defaults: defaults)
        store.setUser(.fixture(), token: .fixture())

        store.clear()

        #expect(store.session == .guest)
        #expect(DefaultSessionStore(defaults: defaults).session == .guest)
    }

    @Test("Signing in as someone else replaces the shopper rather than adding one")
    func signingInAgainReplaces() {
        let store = DefaultSessionStore(defaults: makeDefaults())
        store.setUser(.fixture(), token: .fixture())

        store.setUser(
            User(
                id: UserID(rawValue: 2),
                email: Email("other@example.com"),
                name: PersonName(first: "Grace", last: "Hopper")
            ),
            token: AuthToken(value: "other", expiresAt: Date().addingTimeInterval(3600))
        )

        #expect(store.session.user?.id == UserID(rawValue: 2))
        #expect(store.authToken?.value == "other")
    }
}

private extension User {
    static func fixture() -> User {
        User(
            id: UserID(rawValue: 1),
            email: Email("shopper@example.com"),
            name: PersonName(first: "Ada", last: "Lovelace")
        )
    }
}

private extension AuthToken {
    static func fixture(expiresIn seconds: TimeInterval = 3600) -> AuthToken {
        AuthToken(value: "token", expiresAt: Date().addingTimeInterval(seconds))
    }
}
