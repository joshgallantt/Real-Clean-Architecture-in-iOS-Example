public struct AuthenticationPrompt: Equatable, Sendable {
    public let title: String
    public let message: String
    public let icon: String

    public init(
        title: String = "Account Required",
        message: String,
        icon: String = "lock.shield.fill"
    ) {
        self.title = title
        self.message = message
        self.icon = icon
    }

    public static let `default` = AuthenticationPrompt(message: "Sign in to carry on")
}
