import SwiftUI

struct AuthSheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary, Color(.tertiarySystemFill))
        }
        .accessibilityLabel("Close")
        .padding(16)
    }
}
