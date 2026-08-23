// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import Combine
import Foundation
import Session
import SessionTestSupport
@testable import AccountUI

@MainActor
final class SpyLogout: LogoutUseCase, @unchecked Sendable {
    private(set) var callCount = 0

    func callAsFunction() async {
        callCount += 1
    }
}

// MARK: - Fixtures

extension User {
    static func fixture(id: Int = 1, first: String = "Ada") -> User {
        User(
            id: UserID(rawValue: id),
            email: Email("\(first.lowercased())@example.com"),
            name: PersonName(first: first, last: nil)
        )
    }
}
