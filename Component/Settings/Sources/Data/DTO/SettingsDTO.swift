import Settings

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
struct SettingsDTO: Codable, Sendable {
    let pushNotifications: Bool
    let bagOutOfStockNotice: Bool
    let bagPriceIncreases: Bool
    let bagPriceDecreases: Bool
    let favoritesWaitlistSection: Bool
    let favoritesBackInStockSection: Bool

    init(settings: Settings) {
        self.pushNotifications = settings.pushNotifications
        self.bagOutOfStockNotice = settings.bagOutOfStockNotice
        self.bagPriceIncreases = settings.bagPriceIncreases
        self.bagPriceDecreases = settings.bagPriceDecreases
        self.favoritesWaitlistSection = settings.favoritesWaitlistSection
        self.favoritesBackInStockSection = settings.favoritesBackInStockSection
    }

    func toDomain() -> Settings {
        Settings(
            pushNotifications: pushNotifications,
            bagOutOfStockNotice: bagOutOfStockNotice,
            bagPriceIncreases: bagPriceIncreases,
            bagPriceDecreases: bagPriceDecreases,
            favoritesWaitlistSection: favoritesWaitlistSection,
            favoritesBackInStockSection: favoritesBackInStockSection
        )
    }
}
