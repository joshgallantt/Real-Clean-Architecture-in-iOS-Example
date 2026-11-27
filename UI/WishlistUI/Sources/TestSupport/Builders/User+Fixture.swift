import Session

extension User {
    static func fixture() -> User {
        User(id: UserID(rawValue: 1), email: Email("ada@example.com"), name: PersonName(first: "Ada", last: nil))
    }
}
