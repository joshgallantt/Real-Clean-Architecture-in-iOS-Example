/// An event as the Firebase SDK takes it: Google's name for it, a flat bag of parameters, and the
/// items it was about under Google's item keys.
public struct FirebaseEventDTO: Equatable, Sendable {
    public let name: String
    public let parameters: [String: String]
    public let items: [[String: String]]

    public init(name: String, parameters: [String: String], items: [[String: String]]) {
        self.name = name
        self.parameters = parameters
        self.items = items
    }
}
