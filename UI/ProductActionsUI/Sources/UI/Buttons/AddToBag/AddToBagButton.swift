import SwiftUI
import UIKit

public struct AddToBagButton: View {
    @State private var viewModel: BagButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> BagButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            HStack {
                Image(systemName: "bag.fill")
                Text(viewModel.quantity > 0 ? "Add Another (\(viewModel.quantity) in Bag)" : "Add to Bag")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .onAppear { viewModel.onAppear() }
    }
}
