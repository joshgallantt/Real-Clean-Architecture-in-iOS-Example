import SwiftUI
import UIKit

public struct BagButtonView: View {
    @StateObject private var viewModel: BagButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> BagButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bag.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())

                if viewModel.quantity > 0 {
                    Text("\(viewModel.quantity)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.accentColor, in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
