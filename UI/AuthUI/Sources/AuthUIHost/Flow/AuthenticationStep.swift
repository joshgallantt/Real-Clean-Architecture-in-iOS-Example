import AuthUI

/// A step of the flow, and so also where the presenter can start it.
enum AuthenticationStep {
    case chooser(AuthenticationPrompt)
    case logIn
    case createAccount
}
