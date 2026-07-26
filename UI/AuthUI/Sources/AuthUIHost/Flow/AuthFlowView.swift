import SwiftUI

/// The flow's one and only sheet. Both forms and the confirmation are the same surface
/// resolving in place, so the user crosses the whole thing without a sheet ever dismissing
/// out from under them.
struct AuthFlowView: View {
    @StateObject private var viewModel: AuthFlowViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: @autoclosure @escaping () -> AuthFlowViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            if let confirmation = viewModel.confirmation {
                AuthSuccessView(title: confirmation.title, message: confirmation.message)
                    .padding(24)
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
        .animation(.easeInOut(duration: 0.25), value: viewModel.confirmation)
        // Pinned to the sheet rather than to the content, so it stays put when the content
        // changes — a form giving way to its confirmation, or one form to the other.
        .overlay(alignment: .topTrailing) {
            AuthSheetCloseButton {
                if viewModel.closeRequested() { dismiss() }
            }
        }
        // A rubber-banding swipe is the system's own way of saying "not like that"; the
        // close button is right there, and it explains itself.
        .interactiveDismissDisabled(viewModel.hasUnsavedInput)
        .confirmationDialog(
            "Discard your details?",
            isPresented: $viewModel.isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        // Full height, and only ever that: no detents to resize between, so swapping forms —
        // or a form giving way to its confirmation — can't make the sheet lurch. The form
        // scrolls within it, which is what keeps the keyboard from pushing the header off
        // the top edge.
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    @ViewBuilder
    private var form: some View {
        switch viewModel.step {
        case .logIn:
            LogInStepView(
                viewModel: viewModel.logIn,
                header: viewModel.header,
                onShowPeer: viewModel.showPeer
            )
        case .createAccount:
            CreateAccountStepView(
                viewModel: viewModel.createAccount,
                header: viewModel.header,
                onShowPeer: viewModel.showPeer
            )
        }
    }
}
