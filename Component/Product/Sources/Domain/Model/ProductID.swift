/// Opaque identity for a product. The backend's token format — an integer today — is not
/// the domain's business, and nothing inward of the data layer reads `rawValue`.
///
/// This is the one part of a product that other contexts are allowed to hold: a bag and a
/// wishlist both refer to products they do not own, and identity is what makes that
/// reference safe. Being a type rather than an `Int` is what stops a category id, a user
/// id, or a quantity being passed where a product was meant.
public struct ProductID: Equatable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
