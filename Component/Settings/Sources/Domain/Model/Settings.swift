/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities, Value Objects, Services: no identity of
/// its own, so equality is by value. Ch. 10 — Side-Effect-Free Functions: `setting(_:to:)` answers
/// with a new `Settings` rather than mutating the one it was asked of.
public struct Settings: Equatable, Sendable {
    public let pushNotifications: Bool
    public let bagOutOfStockNotice: Bool
    public let bagPriceIncreases: Bool
    public let bagPriceDecreases: Bool
    public let favoritesWaitlistSection: Bool
    public let favoritesBackInStockSection: Bool

    public init(
        pushNotifications: Bool = false,
        bagOutOfStockNotice: Bool = true,
        bagPriceIncreases: Bool = true,
        bagPriceDecreases: Bool = true,
        favoritesWaitlistSection: Bool = true,
        favoritesBackInStockSection: Bool = true
    ) {
        self.pushNotifications = pushNotifications
        self.bagOutOfStockNotice = bagOutOfStockNotice
        self.bagPriceIncreases = bagPriceIncreases
        self.bagPriceDecreases = bagPriceDecreases
        self.favoritesWaitlistSection = favoritesWaitlistSection
        self.favoritesBackInStockSection = favoritesBackInStockSection
    }

    public func value(for key: SettingKey) -> Bool {
        switch key {
        case .pushNotifications: pushNotifications
        case .bagOutOfStockNotice: bagOutOfStockNotice
        case .bagPriceIncreases: bagPriceIncreases
        case .bagPriceDecreases: bagPriceDecreases
        case .favoritesWaitlistSection: favoritesWaitlistSection
        case .favoritesBackInStockSection: favoritesBackInStockSection
        }
    }

    public func setting(_ key: SettingKey, to isOn: Bool) -> Settings {
        Settings(
            pushNotifications: key == .pushNotifications ? isOn : pushNotifications,
            bagOutOfStockNotice: key == .bagOutOfStockNotice ? isOn : bagOutOfStockNotice,
            bagPriceIncreases: key == .bagPriceIncreases ? isOn : bagPriceIncreases,
            bagPriceDecreases: key == .bagPriceDecreases ? isOn : bagPriceDecreases,
            favoritesWaitlistSection: key == .favoritesWaitlistSection ? isOn : favoritesWaitlistSection,
            favoritesBackInStockSection: key == .favoritesBackInStockSection ? isOn : favoritesBackInStockSection
        )
    }
}
