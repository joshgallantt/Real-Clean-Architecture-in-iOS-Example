import SwiftUI
import UIKit

public struct WishlistButtonView: View {
    @StateObject private var viewModel: WishlistButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> WishlistButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.didTap()
        } label: {
            Image(systemName: viewModel.isInWishlist ? "heart.fill" : "heart")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(viewModel.isInWishlist ? .red : .primary)
                .symbolEffect(.bounce, value: viewModel.isInWishlist)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
