import Combine
import Foundation
import Settings
@testable import SettingsUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper saw and tapped, never which type stored it.
///
/// What is faked here is the shop: a shopper's settings, whether they are signed in, and a write
/// that keeps what it is given. Which of those settings a shopper actually has is not decided here —
/// `Setting.offered(from:signedIn:)` decides it, in `Component/Settings`, the same call the app
/// makes.
final class Shopper {
    private let settingsSubject: CurrentValueSubject<Settings, Never>
    private let signedInSubject: CurrentValueSubject<Bool, Never>
    private let setSetting: StubSetSetting

    private lazy var screen = SettingsScreenViewModel(
        observeOfferedSettings: StubObserveOfferedSettings(
            settings: settingsSubject,
            signedIn: signedInSubject
        ),
        setSetting: setSetting
    )

    init(signedIn: Bool = false, settings: Settings = Settings()) {
        settingsSubject = CurrentValueSubject(settings)
        signedInSubject = CurrentValueSubject(signedIn)
        setSetting = StubSetSetting(settings: settingsSubject)
    }

    // MARK: - What a shopper does

    func opensScreen() {
        screen.onAppear()
    }

    func toggles(_ key: SettingKey, to isOn: Bool) {
        screen.didToggle(key, to: isOn)
    }

    /// What the shop says the moment somebody signs in: a shopper with an account now, and that
    /// account's own settings, arriving together the way the domain's owner switch delivers them.
    func signIn(settings: Settings = Settings()) {
        settingsSubject.send(settings)
        signedInSubject.send(true)
    }

    func signOut(settings: Settings = Settings()) {
        settingsSubject.send(settings)
        signedInSubject.send(false)
    }

    // MARK: - What a shopper sees

    /// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: "The role of the testing API
    /// is to hide the structure of the application from the tests." These answer what a shopper read
    /// off the screen rather than handing back the model it was drawn from, so `SettingsSectionModel`
    /// and `SettingRow` can be reshaped without a test that never mentions them having to change.
    var sectionsShown: [String] { screen.sections.map(\.title) }

    /// Asked a section at a time, because which section a row is under is part of what a shopper
    /// sees — a flat list of every row reads the same however they are grouped.
    func rowsShown(in section: String) -> [String] {
        screen.sections.first { $0.title == section }?.rows.map(\.title) ?? []
    }

    /// `nil` when the screen is not showing that setting at all, which is a different answer from
    /// showing it switched off.
    func isOn(_ key: SettingKey) -> Bool? {
        screen.sections.flatMap(\.rows).first { $0.id == key }?.isOn
    }

    func settle() async {
        for _ in 0..<200 { await Task.yield() }
    }
}

// MARK: - The shop the screen is reading

private struct StubObserveOfferedSettings: ObserveOfferedSettingsUseCase, @unchecked Sendable {
    let settings: CurrentValueSubject<Settings, Never>
    let signedIn: CurrentValueSubject<Bool, Never>

    @MainActor
    func callAsFunction() -> AnyPublisher<[Setting], Never> {
        settings
            .combineLatest(signedIn) { Setting.offered(from: $0, signedIn: $1) }
            .eraseToAnyPublisher()
    }
}

/// A working double, not a store of canned answers: a successful write updates the same settings
/// stream the screen observes, exactly as the real repository publishes after it keeps a change.
private final class StubSetSetting: SetSettingUseCase, @unchecked Sendable {
    let settings: CurrentValueSubject<Settings, Never>

    init(settings: CurrentValueSubject<Settings, Never>) {
        self.settings = settings
    }

    @MainActor
    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        settings.send(settings.value.setting(key, to: isOn))
        return .success(())
    }
}
