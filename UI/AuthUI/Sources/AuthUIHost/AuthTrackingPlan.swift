/// The tracking plan for signing in: its screens, every element it reports and the way in it
/// offers, named once.
///
/// The sheet is two screens, not one, because a shopper who opens it to log in and leaves to create
/// an account has been somewhere else. Reporting both as `auth` would make the switch invisible.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
enum AuthTrackingPlan {
    static let welcome = "welcome"

    static func screen(for mode: AuthMode) -> String {
        switch mode {
        case .logIn: "auth_log_in"
        case .createAccount: "auth_create_account"
        }
    }

    static let logIn = "log_in"
    static let createAccount = "create_account"
    static let continueAsGuest = "continue_as_guest"
    static let submit = "submit"

    /// The way from one mode to the other, named for where it goes.
    static func switchMode(to mode: AuthMode) -> String {
        switch mode {
        case .logIn: "switch_to_log_in"
        case .createAccount: "switch_to_create_account"
        }
    }

    /// Seen whenever a submit comes back refused. Against `submit`, it is the rate at which
    /// shoppers are told no.
    static let error = "auth_error"

    /// How a shopper gets in through this sheet, in the report's spelling. One way today; the day
    /// there is a passkey, it is a second case here and the sheet says which.
    enum Method: String {
        case email
    }
}
