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

    /// What a report calls this snackbar: its title in the report's spelling, so "In the Bag" is
    /// `in_the_bag`. Here because every screen that shows a snackbar reports that it was seen,
    /// and they must all spell it the same way.
    public var trackingName: String {
        title.lowercased().split { !$0.isLetter && !$0.isNumber }.joined(separator: "_")
    }

    public var displayDuration: Duration {
        .seconds(3)
    }
}
