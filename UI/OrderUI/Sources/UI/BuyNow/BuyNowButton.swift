import SwiftUI
import UIKit

/// The express path: one product, one tap, no bag. It sits under Add to Bag rather than replacing
/// it, because the two are different intentions — one is "I am still shopping" and the other is
/// "I am done" — and a screen that offered only the second would make a shopper who wanted to keep
/// browsing check out to keep anything.
public struct BuyNowButton: View {
    @StateObject private var viewModel: BuyNowButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> BuyNowButtonViewModel) {
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
                    Text("Buy Now · \(viewModel.priceLabel)")
                }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.primary)
        /// Disabled rather than merely ignoring the second tap, so a shopper on a slow connection
        /// can see that the first one was taken. Paying twice for the same thing is the one mistake
        /// this screen must not allow.
        .disabled(viewModel.isPlacing)
    }
}
