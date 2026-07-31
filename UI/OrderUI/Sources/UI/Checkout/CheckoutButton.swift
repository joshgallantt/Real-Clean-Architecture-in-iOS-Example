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
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.primary)
        .disabled(viewModel.isPlacing || viewModel.isEmpty)
    }
}
