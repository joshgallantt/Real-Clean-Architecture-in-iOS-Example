import Settings

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here — including the one place a
/// `SettingKey` becomes a string and has to be recognised again coming back.
struct SettingsDTO: Codable, Sendable {
    let values: [String: Bool]

    init(settings: Settings) {
        values = Dictionary(
            uniqueKeysWithValues: SettingKey.allCases.map { ($0.rawValue, settings.value(for: $0)) }
        )
    }

    func toDomain() -> Settings {
        Settings(
            Dictionary(
                uniqueKeysWithValues: values.compactMap { name, isOn in
                    SettingKey(rawValue: name).map { ($0, isOn) }
                }
            )
        )
    }
}
