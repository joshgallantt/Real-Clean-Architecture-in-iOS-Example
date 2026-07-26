import SwiftUI

struct AuthSheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary, Color(.tertiarySystemFill))
        }
        .accessibilityLabel("Close")
        .padding(16)
    }
}
