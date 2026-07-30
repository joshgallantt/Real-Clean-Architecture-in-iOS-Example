import SwiftUI

struct AuthSheetView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    init(viewModel: @autoclosure @escaping () -> AuthViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            if let message = viewModel.confirmationMessage {
                AuthSuccessView(title: viewModel.confirmationTitle, message: message)
                    .padding(24)
            } else {
                AuthFormView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button {
                closeTapped()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary, Color(.tertiarySystemFill))
            }
            .accessibilityLabel("Close")
            .padding(16)
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedInput)
        .confirmationDialog(
            "Discard your details?",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func closeTapped() {
        guard viewModel.hasUnsavedInput else {
            dismiss()
            return
        }
        isConfirmingDiscard = true
    }
}
