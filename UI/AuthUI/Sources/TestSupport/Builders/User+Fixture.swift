import Session

extension User {
    static func fixture(first: String = "Ada") -> User {
        User(id: UserID(rawValue: 1), email: Email("\(first.lowercased())@example.com"), name: PersonName(first: first, last: nil))
    }
}
