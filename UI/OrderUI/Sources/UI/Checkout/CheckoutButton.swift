import SwiftUI
import UIKit

/// The bag's way out. It shows the total it is about to charge, because a button that takes money
/// should say how much before it is tapped rather than after.
public struct CheckoutButton: View {
    @StateObject private var viewModel: CheckoutButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> CheckoutButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            HStack {
                if viewModel.isPlacing {
                    ProgressView()
                        .tint(Color(uiColor: .systemBackground))
                } else {
                    Image(systemName: "bolt.fill")
                    Text("Check Out · \(viewModel.totalLabel)")
                }
            }
            .fontWeight(.semibold)
            /// `.borderedProminent` fills the background with the tint but does not work out a
            /// contrasting colour for the label, so a `.primary` tint left white-on-white text in
            /// dark mode. Naming the background colour as the foreground inverts with the theme:
            /// black text on the white button, white text on the black one.
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.primary)
        .disabled(viewModel.isPlacing || viewModel.isEmpty)
    }
}
