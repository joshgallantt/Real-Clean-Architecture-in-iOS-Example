import Foundation

/// Greets the user by name, and reads just as well for the accounts that don't have one.
enum AuthGreeting {
    static func welcomeBack(_ firstName: String?) -> String {
        greeting("Welcome back", firstName)
    }

    static func welcome(_ firstName: String?) -> String {
        greeting("Welcome", firstName)
    }

    private static func greeting(_ lead: String, _ firstName: String?) -> String {
        guard let name = firstName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "\(lead)."
        }
        return "\(lead), \(name)."
    }
}
