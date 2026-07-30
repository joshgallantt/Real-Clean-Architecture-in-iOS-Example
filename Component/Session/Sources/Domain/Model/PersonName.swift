import Foundation

/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: a last name is
/// optional, and saying so in the type is the point. Two loose strings leave that intent invisible
/// and the rule applied to whichever half the author had in mind.
///
/// Evans — Value Objects. Fowler, *PoEAA* (2002) — Special Case: absence is `nil`, not a blank to
/// be checked for at every use.
public struct PersonName: Equatable, Sendable {
    public let first: String
    public let last: String?

    public init(first: String, last: String?) {
        self.first = first
        self.last = last.flatMap { Self.trimmed($0).isEmpty ? nil : $0 }
    }

    public var isValid: Bool {
        !Self.trimmed(first).isEmpty
    }

    public var full: String {
        [Self.trimmed(first), last.map(Self.trimmed) ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
