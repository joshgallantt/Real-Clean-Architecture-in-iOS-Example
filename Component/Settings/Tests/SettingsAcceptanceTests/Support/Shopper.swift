import Combine
import Foundation
import Session
import Settings
import SettingsData
import SettingsDI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper turned on or off, never which type stored it — so the tests survive the feature being
/// rearranged underneath them.
///
/// Martin, Ch. 26 — The Main Component: the feature wired exactly as the composition root will wire
/// it, over a real `FileSettingsStore` in a temporary directory — real repository, real DTOs, real
/// JSON on a real disk. Only the session, which this component only ever reads, is stubbed.
final class Shopper {
    private let directory: URL
    private let sessions: CurrentValueSubject<Session, Never>
    private let di: SettingsDI
    private var cancellables = Set<AnyCancellable>()

    private(set) var settings = Settings()

    init(in directory: URL = .newTemporaryDirectory, signedInAs userId: Int? = nil) {
        self.directory = directory
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = SettingsDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: FileSettingsStore(directory: directory)
        )

        di.observeSettingsUseCase()
            .sink { [weak self] in self?.settings = $0 }
            .store(in: &cancellables)
    }

    // MARK: - What a shopper does

    @discardableResult
    func turn(_ key: SettingKey, _ isOn: Bool) async -> Result<Void, SettingsError> {
        await di.setSettingUseCase(key, isOn: isOn)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    // MARK: - Leaving and coming back

    /// No waiting for anything to settle: a change is not done until what it changed is kept, so by
    /// the time `turn` has returned there is nothing in flight to wait for.
    func leaveAndComeBack() -> Shopper {
        Shopper(in: directory, signedInAs: signedInUserId)
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

// MARK: - The session, which Settings only ever reads

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

// MARK: - Fixtures

extension URL {
    static var newTemporaryDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    /// Somewhere settings genuinely cannot be written: a directory that cannot be created, because
    /// the path it would sit under is a file. A real failure rather than a fake store — the store
    /// under test is the one that ships.
    static func unwritableDirectory() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("not a directory".utf8).write(to: file)
        return file.appending(path: "settings", directoryHint: .isDirectory)
    }
}

extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
