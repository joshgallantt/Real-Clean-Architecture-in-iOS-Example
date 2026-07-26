import AuthUI

/// What the first thing on the sheet says. Either the step's own words, or the reason the
/// feature gave for opening it.
struct AuthHeader: Equatable {
    let icon: String
    let title: String
    let subtitle: String

    init(icon: String, title: String, subtitle: String) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    init(_ prompt: AuthenticationPrompt) {
        self.init(icon: prompt.icon, title: prompt.title, subtitle: prompt.message)
    }
}
