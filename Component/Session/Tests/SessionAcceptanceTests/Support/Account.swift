import Combine
import Foundation
import Session
import SessionData
import SessionDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper typed into the form and what happened, never which type validated it.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it
/// — the same `FakeAuthClient` the app ships, over `UserDefaults` suites of their own. What signs a
/// shopper in here is what signs them in on a device.
final class Account {
    private let defaults: UserDefaults
    private let tokenLifetime: TimeInterval
    private let di: SessionDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var session: Session = .guest

    init(sharing defaults: UserDefaults = .newSuite, staysSignedInFor tokenLifetime: TimeInterval = .aWeek) {
        self.defaults = defaults
        self.tokenLifetime = tokenLifetime
        self.di = SessionDI(
            sessionStore: DefaultSessionStore(defaults: defaults),
            authClient: FakeAuthClient(
                userStore: UserDefaultsUserStore(defaults: defaults),
                tokenLifetime: tokenLifetime
            )
        )

        di.observeSessionUseCase()
            .sink { [weak self] in self?.session = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper sees

    var isSignedIn: Bool { session.isLoggedIn }

    var nameOnScreen: String? { session.user?.name.full }

    // MARK: - What a shopper types

    @discardableResult
    func createAccount(
        firstName: String = "Ada",
        lastName: String? = "Lovelace",
        email: String = "ada@example.com",
        password: String = "hunter2"
    ) async -> Result<Void, CreateAccountError> {
        await di.createAccountUseCase(
            name: PersonName(first: firstName, last: lastName),
            email: Email(email),
            password: Password(password)
        )
    }

    @discardableResult
    func logIn(email: String = "ada@example.com", password: String = "hunter2") async -> Result<Void, LoginError> {
        await di.loginUseCase(email: Email(email), password: Password(password))
    }

    func logOut() async {
        await di.logoutUseCase()
    }

    /// The shopper closes the app and opens it again. Everything they are is read back from the
    /// device, so a session that does not survive this does not survive a relaunch.
    func leaveAndComeBack(staysSignedInFor tokenLifetime: TimeInterval? = nil) -> Account {
        Account(sharing: defaults, staysSignedInFor: tokenLifetime ?? self.tokenLifetime)
    }
}

extension UserDefaults {
    static var newSuite: UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }
}

extension TimeInterval {
    static let aWeek: TimeInterval = 60 * 60 * 24 * 7
    static let alreadyOver: TimeInterval = -1
}

extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
