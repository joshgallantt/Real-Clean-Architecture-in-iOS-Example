/// A shopper the shop knows by name.
///
/// Carries `Email` rather than a string, because an account's address is a persisted fact
/// and the type is what says it has been through the rule. A half-typed address belongs to
/// a text field, not to a `User`.
public struct User: Equatable, Sendable, Identifiable {
    public let id: UserID
    public let email: Email
    public let name: PersonName

    public init(id: UserID, email: Email, name: PersonName) {
        self.id = id
        self.email = email
        self.name = name
    }
}
