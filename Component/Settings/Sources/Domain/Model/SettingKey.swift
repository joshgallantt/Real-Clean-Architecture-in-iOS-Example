/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Entities, Value Objects, Services: identifies one
/// of the six settings without a caller reaching for a raw string. Ch. 9 — Making Implicit Concepts
/// Explicit: which section a key belongs to, and whether it requires an account, are rules of the
/// key itself rather than facts a caller has to already know.
public enum SettingKey: CaseIterable, Equatable, Hashable, Sendable {
    case pushNotifications
    case bagOutOfStockNotice
    case bagPriceIncreases
    case bagPriceDecreases
    case favoritesWaitlistSection
    case favoritesBackInStockSection

    public var section: SettingsSection {
        switch self {
        case .pushNotifications:
            .notifications
        case .bagOutOfStockNotice, .bagPriceIncreases, .bagPriceDecreases:
            .bag
        case .favoritesWaitlistSection, .favoritesBackInStockSection:
            .favorites
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: which settings need a signed-in
    /// shopper is a rule of the key, decided once here rather than re-decided at every call site.
    var requiresAuthentication: Bool {
        section == .favorites
    }

    /// Martin, Ch. 20 — Business Rules: which of them a shopper is offered, composed once from the
    /// rule above. `ObserveOfferedSettingsUseCase` publishes what this returns and
    /// `SetSettingUseCase` refuses what it leaves out, so nothing is ever offered that would then be
    /// declined. Neither this nor the rule above leaves the component: what a caller outside it can
    /// reach is the answer, `Setting.offered(from:signedIn:)`, never the predicate to re-apply.
    static func offered(signedIn: Bool) -> [SettingKey] {
        allCases.filter { !$0.requiresAuthentication || signedIn }
    }
}
