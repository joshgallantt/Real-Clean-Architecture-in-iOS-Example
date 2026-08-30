// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import Foundation
import ProductTestSupport
import SessionTestSupport
import SwiftUI
import Session
import SheetUI
@testable import AuthUIDI

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

extension User {
    static func fixture(first: String = "Ada") -> User {
        User(id: UserID(rawValue: 1), email: Email("\(first.lowercased())@example.com"), name: PersonName(first: first, last: nil))
    }
}
