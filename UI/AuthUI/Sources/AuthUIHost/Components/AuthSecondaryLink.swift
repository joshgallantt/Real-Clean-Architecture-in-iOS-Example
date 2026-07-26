import SwiftUI

/// The way to the other form. Deliberately quiet next to the primary button — it's the
/// answer for the minority who came in the wrong door, not a second call to action.
struct AuthSecondaryLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }
}
