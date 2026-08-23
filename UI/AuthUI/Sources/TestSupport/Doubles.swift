// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import Foundation
import SessionTestSupport
import SwiftUI
import Session
import SheetUI
@testable import AuthUIDI

@MainActor
final class StubLogin: LoginUseCase, @unchecked Sendable {
    var result: Result<Void, LoginError> = .success(())
    private(set) var calls: [(email: Email, password: Password)] = []

    func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError> {
        calls.append((email, password))
        return result
    }
}

@MainActor
final class StubCreateAccount: CreateAccountUseCase, @unchecked Sendable {
    var result: Result<Void, CreateAccountError> = .success(())
    private(set) var calls: [(name: PersonName, email: Email, password: Password)] = []

    func callAsFunction(name: PersonName, email: Email, password: Password) async -> Result<Void, CreateAccountError> {
        calls.append((name, email, password))
        return result
    }
}

@MainActor
final class SpySheetPresenter: SheetPresenting {
    private(set) var presentCount = 0
    private var lastOnDismiss: (() -> Void)?

    func present<Content: View>(onDismiss: (() -> Void)?, content: () -> Content) {
        presentCount += 1
        lastOnDismiss = onDismiss
    }

    func dismiss() {}

    func userDismissedTheSheet() {
        lastOnDismiss?()
    }
}

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
