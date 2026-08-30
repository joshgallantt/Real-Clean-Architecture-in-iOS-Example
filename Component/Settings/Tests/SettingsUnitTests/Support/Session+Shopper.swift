import Session

extension Session {
    static let shopper: Session = .authenticated(
        User(
            id: UserID(rawValue: 42),
            email: Email("shopper@example.com"),
            name: PersonName(first: "Ada", last: nil)
        )
    )
}
