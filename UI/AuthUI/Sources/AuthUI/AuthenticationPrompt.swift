/// Why the user is being asked to authenticate. Features supply their own so the ask reads
/// as part of what the user was trying to do.
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

    public static let `default` = AuthenticationPrompt(message: "Sign in to continue")
}
