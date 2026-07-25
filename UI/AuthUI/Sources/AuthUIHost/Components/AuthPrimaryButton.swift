import SwiftUI

struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Held in place, invisible, so the button keeps its size while it works.
                Text(title)
                    .fontWeight(.semibold)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isLoading ? Color(.systemGray3) : .accentColor)
        .controlSize(.large)
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}
