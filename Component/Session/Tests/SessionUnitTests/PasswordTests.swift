import Foundation
import Testing
@testable import Session

@Suite("Password")
struct PasswordTests {
    @Test("Long enough is valid")
    func longEnough() {
        #expect(Password("hunter2").isValid)
    }

    @Test("Exactly the minimum is long enough")
    func exactlyTheMinimum() {
        #expect(Password(String(repeating: "a", count: Password.minimumLength)).isValid)
    }

    @Test("One short is not")
    func oneShort() {
        #expect(Password(String(repeating: "a", count: Password.minimumLength - 1)).isValid == false)
    }

    @Test("Empty is not")
    func empty() {
        #expect(Password("").isValid == false)
    }

    @Test("Spaces count as characters — this rule is about length and nothing else")
    func spacesCount() {
        #expect(Password("    ").isValid)
    }
}
