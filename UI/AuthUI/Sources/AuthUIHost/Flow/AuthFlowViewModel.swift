import Combine
import AuthUI

/// The whole flow, on one sheet: which form is showing, both forms, and the state the
/// sheet's own chrome needs — what the close button should do, and whether the flow has
/// finished.
@MainActor
final class AuthFlowViewModel: ObservableObject {
    /// Both forms are owned here rather than by their views, so a form keeps what the user
    /// typed while they go and look at the other one.
    let logIn: LogInStepViewModel
    let createAccount: CreateAccountStepViewModel

    @Published private(set) var step: AuthenticationStep
    @Published var isConfirmingDiscard = false

    private let openedAt: AuthenticationStep
    private let prompt: AuthenticationPrompt?
    private let onAuthenticated: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(
        step: AuthenticationStep,
        prompt: AuthenticationPrompt?,
        logIn: LogInStepViewModel,
        createAccount: CreateAccountStepViewModel,
        onAuthenticated: @escaping () -> Void
    ) {
        self.step = step
        self.openedAt = step
        self.prompt = prompt
        self.logIn = logIn
        self.createAccount = createAccount
        self.onAuthenticated = onAuthenticated

        // SwiftUI only observes the object it was handed, and the sheet's chrome reads
        // through to the forms' state — so their changes have to be passed on by hand.
        logIn.objectWillChange
            .merge(with: createAccount.objectWillChange)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Whichever form succeeds ends the flow, and it can only end once.
        logIn.$confirmation
            .merge(with: createAccount.$confirmation)
            .compactMap { $0 }
            .first()
            .sink { [weak self] _ in self?.onAuthenticated() }
            .store(in: &cancellables)
    }

    /// Set once the user is through. While it holds a value the sheet shows nothing else.
    var confirmation: AuthConfirmation? {
        logIn.confirmation ?? createAccount.confirmation
    }

    /// Only the step the flow opened on wears the prompt: it is the reason the sheet is
    /// here, and it stops being the reason once the user has chosen to go elsewhere in it.
    var header: AuthHeader {
        guard step == openedAt, let prompt else { return step.header }
        return AuthHeader(prompt)
    }

    /// Whether closing now would throw away something the user typed. Not once they're
    /// through — by then the fields have served their purpose.
    var hasUnsavedInput: Bool {
        confirmation == nil && (logIn.hasInput || createAccount.hasInput)
    }

    func showPeer() {
        step = step.peer
    }

    /// - Returns: whether the sheet can close now. When it can't, the discard confirmation
    ///   is up and the user's answer decides.
    func closeRequested() -> Bool {
        guard hasUnsavedInput else { return true }
        isConfirmingDiscard = true
        return false
    }
}
