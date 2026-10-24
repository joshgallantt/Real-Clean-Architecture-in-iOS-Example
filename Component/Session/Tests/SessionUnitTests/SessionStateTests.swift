import Foundation
import Testing
@testable import Session

@Suite("Session")
struct SessionStateTests {
    private let ada = User(
        id: UserID(rawValue: 1),
        email: Email("ada@example.com"),
        name: PersonName(first: "Ada", last: nil)
    )

    @Test("A guest is not logged in and is nobody")
    func guest() {
        #expect(Session.guest.isLoggedIn == false)
        #expect(Session.guest.user == nil)
    }

    @Test("Being authenticated is being logged in, as somebody")
    func authenticated() {
        #expect(Session.authenticated(ada).isLoggedIn)
        #expect(Session.authenticated(ada).user == ada)
    }

    @Test("Two sessions for the same person are the same session")
    func equality() {
        #expect(Session.authenticated(ada) == Session.authenticated(ada))
        #expect(Session.authenticated(ada) != Session.guest)
    }
}
