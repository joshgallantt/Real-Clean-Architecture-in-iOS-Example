/// Evans, *Domain-Driven Design* (2003) — Entities.
///
/// Evans — Value Objects: every field is a type that has already been past its own rule. An `Email`
/// has; a `String` has not.
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
