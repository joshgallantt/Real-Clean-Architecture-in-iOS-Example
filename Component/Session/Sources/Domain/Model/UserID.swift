/// Opaque identity for a shopper. The format the shop mints — an integer today — is not
/// the domain's business, and nothing inward of the data layer reads `rawValue`.
///
/// Other contexts hold this to say whose bag or whose wishlist something is, so being a
/// type rather than an `Int` is what stops a product id ending up where a shopper was meant.
public struct UserID: Equatable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
