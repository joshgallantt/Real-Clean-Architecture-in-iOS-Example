/// An event as mParticle takes it. mParticle has three kinds of event where Google has one: a
/// screen view, a commerce event with an action on its products, and a custom event of one of a
/// handful of types.
public struct MParticleEventDTO: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case screenView
        case commerce(action: String)
        case custom(type: String)
    }

    public let kind: Kind

    /// The screen's name on a screen view; otherwise the event's own title.
    public let name: String
    public let attributes: [String: String]
    public let products: [[String: String]]

    public init(kind: Kind, name: String, attributes: [String: String], products: [[String: String]]) {
        self.kind = kind
        self.name = name
        self.attributes = attributes
        self.products = products
    }
}
