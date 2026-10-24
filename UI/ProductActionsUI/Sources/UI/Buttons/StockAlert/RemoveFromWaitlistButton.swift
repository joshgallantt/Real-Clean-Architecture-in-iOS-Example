import SwiftUI
import UIKit

/// Taking something off the waitlist, from a card on the list itself. A minus rather than a lit
/// bell, because on a list of things a shopper is already waiting for, a bell says what is true and
/// this has to say what tapping it *does*.
///
/// It takes the bell's shape and place — a circle on the corner of a card — so the two are tapped
/// the same way and a shopper does not have to learn a second control.
public struct RemoveFromWaitlistButton: View {
    @State private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.didTapRemove()
        } label: {
            Image(systemName: "minus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Remove from waitlist")
        .onAppear { viewModel.onAppear() }
    }
}
