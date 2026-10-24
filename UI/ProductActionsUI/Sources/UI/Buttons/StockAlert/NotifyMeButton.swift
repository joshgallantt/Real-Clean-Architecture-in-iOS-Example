import SwiftUI
import UIKit

/// The same thing said at full width, where the details screen would otherwise offer Add to Bag.
public struct NotifyMeButton: View {
    @State private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            HStack {
                Image(systemName: viewModel.isWaiting ? "bell.fill" : "bell")
                Text(viewModel.isWaiting ? "We'll Let You Know" : "Notify Me")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .onAppear { viewModel.onAppear() }
    }
}
