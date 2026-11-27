import SwiftUI
import Tracking
import TrackingUI

/// A row in one of Search's lists, saying where it is when it is tapped or seen. Its position is set
/// on it by the list that placed it, and the list by whoever owns the list — the same way a product
/// card says where it is — so no view model has to count rows to know which one this was.
struct TrackedRow<Label: View>: View {
    @Environment(\.trackingContext) private var trackingContext

    let onTap: (TrackingContext) -> Void
    let onSeen: (TrackingContext) -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            onTap(trackingContext)
        } label: {
            label()
        }
        .onImpression(perform: onSeen)
    }
}
