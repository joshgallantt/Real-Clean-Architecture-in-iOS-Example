import SwiftUI

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
