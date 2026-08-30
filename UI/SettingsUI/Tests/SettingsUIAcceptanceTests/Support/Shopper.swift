import Combine
import Foundation
import Settings
import SettingsTestSupport
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
    private let setSetting: StubSetSettingThatKeeps

    private lazy var screen = SettingsScreenViewModel(
        observeOfferedSettings: StubOfferedSettingsForShopper(
            settings: settingsSubject,
            signedIn: signedInSubject
        ),
        setSetting: setSetting
    )

    init(signedIn: Bool = false, settings: Settings = Settings()) {
        settingsSubject = CurrentValueSubject(settings)
        signedInSubject = CurrentValueSubject(signedIn)
        setSetting = StubSetSettingThatKeeps(settings: settingsSubject)
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
