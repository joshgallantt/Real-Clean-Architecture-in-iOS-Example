/// What the flow says once it has succeeded, before it gets out of the way. The step that
/// succeeded writes it, because only that step knows whether the user has just arrived or
/// come back.
struct AuthConfirmation: Equatable {
    let title: String
    let message: String
}
