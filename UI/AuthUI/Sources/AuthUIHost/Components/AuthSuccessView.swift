import SwiftUI

/// The confirmation every sheet in the flow ends on. Same shape as `AuthSheetHeader`, in
/// green, so the sheet reads as the same surface resolving rather than a new one arriving.
/// Centred in whatever height the sheet already has — resizing the detent to fit it would
/// make the sheet lurch at the exact moment it should feel settled.
struct AuthSuccessView: View {
    let title: String
    let message: String

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: hasAppeared)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { hasAppeared = true }
    }
}
