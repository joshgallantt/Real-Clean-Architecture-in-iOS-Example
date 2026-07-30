import Foundation

public struct Snackbar {
    public let title: String
    public let message: String
    public let icon: String?
    public let action: SnackbarAction?

    public init(title: String, message: String, icon: String? = nil, action: SnackbarAction? = nil) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }

    public var displayDuration: Duration {
        .seconds(3)
    }
}
