import SwiftUI
import UIKit

/// The bell that takes the bag button's place on a card when the shop has run out but expects it
/// back. A bag it cannot fill would be a promise the shop cannot keep; this is the one it can.
public struct StockAlertButtonView: View {
    @State private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            Image(systemName: viewModel.isWaiting ? "bell.fill" : "bell")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(viewModel.isWaiting ? Color.yellow : .primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(viewModel.isWaiting ? "Stop telling me when this is back" : "Tell me when this is back")
        .onAppear { viewModel.onAppear() }
    }
}
