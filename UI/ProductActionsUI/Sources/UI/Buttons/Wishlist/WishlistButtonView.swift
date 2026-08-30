import SwiftUI
import UIKit

public struct WishlistButtonView: View {
    @State private var viewModel: WishlistButtonViewModel

    /// Belongs to the tap, not to the saved state.
    @State private var scale: CGFloat = 1

    public init(viewModel: @autoclosure @escaping () -> WishlistButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            beat()
            viewModel.didTap()
        } label: {
            Image(systemName: viewModel.isInWishlist ? "heart.fill" : "heart")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(viewModel.isInWishlist ? .red : .primary)
                .scaleEffect(scale)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onAppear { viewModel.onAppear() }
    }

    /// Started by the tap and by nothing else.
    ///
    /// Whether the heart is filled is a question about state, and it stays one.
    /// Whether it beats is a question about what the shopper just did, and tying
    /// that to state got it wrong: anything keyed on `isInWishlist` fires when a
    /// value arrives as well as when one changes, so every already-saved card
    /// animated as it scrolled into view. A card appearing is not a tap, and only
    /// a tap should be able to start this.
    private func beat() {
        withAnimation(.easeOut(duration: 0.12)) { scale = 1.3 }
        withAnimation(.easeIn(duration: 0.18).delay(0.12)) { scale = 1 }
    }
}
