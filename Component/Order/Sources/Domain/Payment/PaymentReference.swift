/// What whoever took the money calls it afterwards. Opaque here on purpose — its shape belongs to
/// the processor, and the domain only ever needs to be able to quote it back.
public struct PaymentReference: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
