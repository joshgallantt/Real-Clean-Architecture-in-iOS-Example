import Foundation

/// Evans, *Domain-Driven Design* (2003) — Value Objects.
///
/// Evans — Assertions: the rule is stated once, on the thing it is about. Deliberately lenient and
/// non-failable — a half-typed address must be representable, or the text field cannot use this
/// type and the rule gets copied somewhere it can rot.
public struct Email: Equatable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var isValid: Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed == value, !trimmed.isEmpty else { return false }

        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }

        let local = parts[0]
        let domain = parts[1]
        guard !local.isEmpty, !domain.isEmpty, !domain.hasPrefix("."), !domain.hasSuffix(".") else {
            return false
        }

        return domain.contains(".") && !domain.contains("..")
    }
}
