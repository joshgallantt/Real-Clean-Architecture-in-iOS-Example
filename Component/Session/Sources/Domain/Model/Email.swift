import Foundation

/// What counts as an email address, in one place.
///
/// Deliberately not a smart constructor: `Email("nonsense")` builds, and answers that it
/// is not valid. A shopper halfway through typing has an invalid email and the app must
/// hold it happily — refusing to represent it would mean the text field could not use
/// this type, and the rule would be copied somewhere it could rot.
public struct Email: Equatable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    /// Deliberately lenient. This can only ever guess — the sole way to know an address
    /// is real is to send something to it — so it rejects what is obviously not an
    /// address and lets the shop's own confirmation do the rest.
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
