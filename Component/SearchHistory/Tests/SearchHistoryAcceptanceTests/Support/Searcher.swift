import Combine
import Foundation
import Product
import SearchHistory
import SearchHistoryData
import SearchHistoryDI
import Session

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper typed and what they were shown afterwards, never which type held it.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root wires it,
/// over the real `UserDefaultsSearchHistoryStore` in a suite of its own.
final class Searcher {
    private let defaults: UserDefaults
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: SearchHistoryDI

    init(sharing defaults: UserDefaults = .newSuite, signedInAs userId: Int? = nil) {
        self.defaults = defaults
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = SearchHistoryDI(
            store: UserDefaultsSearchHistoryStore(defaults: defaults),
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions)
        )
    }

    /// What the shopper sees under the search field when they come back to it.
    var recentSearches: [String] {
        di.getSearchHistoryUseCase().terms.map(\.text)
    }

    /// Typing into the field and hitting search. A blank field is not a search, and the app is
    /// what decides that — so the driver goes through the same door the search bar does.
    func search(for typed: String) {
        guard let term = SearchTerm(typed) else { return }
        di.recordSearchUseCase(term)
    }

    func clearHistory() {
        di.clearSearchHistoryUseCase()
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    func leaveAndComeBack() -> Searcher {
        Searcher(sharing: defaults, signedInAs: signedInUserId)
    }

    private var signedInUserId: Int? {
        if case .signedIn(let id) = Owner(sessions.value) { return id.rawValue }
        return nil
    }

    private static func session(forUserId userId: Int?) -> Session {
        guard let userId else { return .guest }
        return .authenticated(
            User(
                id: UserID(rawValue: userId),
                email: Email("shopper@example.com"),
                name: PersonName(first: "Ada", last: nil)
            )
        )
    }
}

// MARK: - The session, which the history only ever reads

private struct StubGetSession: GetSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> Session { sessions.value }
}

private struct StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never> { sessions.eraseToAnyPublisher() }
}

extension UserDefaults {
    static var newSuite: UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }
}
