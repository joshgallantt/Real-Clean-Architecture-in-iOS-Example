import XCTest
@testable import AuthGate

final class AuthGateTests: XCTestCase {
    @MainActor
    func test_conformingGate_runsAction() {
        final class ImmediateGate: AuthGate {
            func requireAuthentication(_ action: @escaping () -> Void) { action() }
        }

        var ran = false
        ImmediateGate().requireAuthentication { ran = true }
        XCTAssertTrue(ran)
    }
}
